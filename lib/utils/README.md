# Call Quality Tracker

Helper utilities for parsing and tracking call quality in OMICall SDK.

## Features

- **Automatic MOS Score Parsing**: Extract Mean Opinion Score (1.0-5.0) from call quality data
- **LCN Tracking**: Track consecutive same LCN values to detect network issues
- **Loading Indicator Logic**: Automatic determination when to show/hide loading overlay
- **Network Recovery Detection**: Detect when connection recovers

## Usage

### Basic Example

```dart
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MyCallScreen extends StatefulWidget {
  @override
  State<MyCallScreen> createState() => _MyCallScreenState();
}

class _MyCallScreenState extends State<MyCallScreen> {
  final CallQualityTracker _qualityTracker = CallQualityTracker();
  String callQuality = "";

  @override
  void initState() {
    super.initState();

    // Set up call quality listener
    OmicallClient.instance.setCallQualityListener((data) {
      // Parse call quality data using helper
      final info = _qualityTracker.parseCallQuality(data);

      debugPrint("CallQualityInfo => $info");

      // Handle loading indicator
      if (info.shouldShowLoading) {
        EasyLoading.show();
      } else if (info.isNetworkRecovered || info.lcn == 0) {
        EasyLoading.dismiss();
      }

      // Display MOS score
      setState(() {
        callQuality = info.mosDisplay; // "4.5", "3.2", etc.
      });
    });
  }

  @override
  void dispose() {
    _qualityTracker.reset(); // Reset tracker when screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Call Quality: $callQuality"),
      ),
    );
  }
}
```

### OLD Way (Manual Parsing - ❌ Not Recommended)

```dart
// Before - Manual parsing and tracking
OmicallClient.instance.setCallQualityListener((data) {
  final quality = data["quality"] as int;
  final stat = data["stat"] as Map<String, dynamic>;
  final currentLcnValue = stat["lcn"] as int? ?? 0;
  final mos = stat["mos"] as double? ?? 0.0;

  // Manual LCN tracking
  if (currentLcnValue == lastLcnValue && currentLcnValue != 0) {
    consecutiveSameLcnCount++;
    if (consecutiveSameLcnCount >= 3) {
      EasyLoading.show();
    }
  } else {
    consecutiveSameLcnCount = 0;
    EasyLoading.dismiss();
  }

  lastLcnValue = currentLcnValue;

  setState(() {
    callQuality = mos > 0 ? mos.toStringAsFixed(1) : "";
  });
});
```

### NEW Way (Using Helper - ✅ Recommended)

```dart
// After - Using helper
final _qualityTracker = CallQualityTracker();

OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  if (info.shouldShowLoading) {
    EasyLoading.show();
  } else if (info.isNetworkRecovered) {
    EasyLoading.dismiss();
  }

  setState(() {
    callQuality = info.mosDisplay;
  });
});
```

## CallQualityInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `mos` | `double` | MOS score (1.0-5.0) |
| `mosDisplay` | `String` | Formatted MOS for display (e.g., "4.5") |
| `qualityText` | `String` | Quality level ("Excellent", "Good", "Fair", "Poor", "Bad") |
| `lcn` | `int` | Loss Connect Number |
| `quality` | `int` | Quality level (0=good, 1=normal, 2=bad) |
| `jitter` | `double` | Jitter in milliseconds |
| `latency` | `double` | Latency in milliseconds |
| `packetLoss` | `double` | Packet loss percentage |
| `shouldShowLoading` | `bool` | Whether to show loading indicator |
| `isNetworkRecovered` | `bool` | Whether network has recovered |
| `consecutiveSameLcnCount` | `int` | Current consecutive count |

## MOS Score Scale

- **MOS ≥ 4.0**: Excellent (xuất sắc)
- **MOS 3.5-4.0**: Good (tốt)
- **MOS 3.0-3.5**: Fair (chấp nhận được)
- **MOS 2.0-3.0**: Poor (kém)
- **MOS < 2.0**: Bad (rất kém)

## Loading Logic

Loading indicator is shown when:
- LCN value stays the same for **3 consecutive events** (network stuck)

Loading indicator is hidden when:
- LCN value changes (network recovered)
- LCN value is 0 (no connection loss)

## API Reference

### CallQualityTracker

#### Methods

- `parseCallQuality(Map data)` → `CallQualityInfo`
  - Parse call quality data from native event
  - Returns parsed information with all calculations done

- `reset()` → `void`
  - Reset tracker state (call when screen closes)

- `state` → `Map<String, int>`
  - Get current tracking state

### CallQualityInfo

Read-only data class containing parsed call quality information.

## Benefits

✅ **Clean Code**: No manual parsing logic in UI code
✅ **Consistent**: Same logic across all screens
✅ **Maintainable**: Update logic in one place
✅ **Type Safe**: Strongly typed data
✅ **Testable**: Easy to unit test
