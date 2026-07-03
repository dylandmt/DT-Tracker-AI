allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Force compatible versions for AGP 8.9.1
    configurations.all {
        resolutionStrategy {
            // Pin maps-utils to 4.0.0 - has updateData method, built with Kotlin 1.9.x
            force("com.google.maps.android:android-maps-utils:4.0.0")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
