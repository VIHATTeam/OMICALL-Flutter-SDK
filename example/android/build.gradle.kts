// Load local.properties for OMICall SDK credentials
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/omicall/OMICall-SDK")
            credentials {
                username = localProperties.getProperty("omicallUsername")
                    ?: project.findProperty("omicallUsername") as? String
                    ?: "omicall"
                password = localProperties.getProperty("omicallPassword")
                    ?: project.findProperty("omicallPassword") as? String
                    ?: throw GradleException(
                        """
                        OMICall SDK GitHub token not found!
                        Please add to local.properties:
                        omicallUsername=omicall
                        omicallPassword=YOUR_GITHUB_PAT_HERE
                        """.trimIndent()
                    )
            }
            authentication {
                create<BasicAuthentication>("basic")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
