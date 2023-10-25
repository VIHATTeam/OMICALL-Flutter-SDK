git tag -a $1 -m "Release $1"
git push origin $1
flutter pub publish --dry-run
flutter pub publish
