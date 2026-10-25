import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
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
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val getNs = androidExt.javaClass.getMethod("getNamespace")
                    if (getNs.invoke(androidExt) == null) {
                        val setNs = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        val pkg = if (project.name.contains("on_audio_query")) {
                            "com.lucasjosino.on_audio_query"
                        } else {
                            "com.fallback.${project.name.replace('-', '_')}"
                        }
                        setNs.invoke(androidExt, pkg)
                    }
                } catch (_: Exception) {}

                try {
                    val getCompileOptions = androidExt.javaClass.getMethod("getCompileOptions")
                    val compileOptions = getCompileOptions.invoke(androidExt)
                    if (compileOptions != null) {
                        compileOptions.javaClass.getMethod("setSourceCompatibility", Any::class.java)
                            .invoke(compileOptions, JavaVersion.VERSION_17)
                        compileOptions.javaClass.getMethod("setTargetCompatibility", Any::class.java)
                            .invoke(compileOptions, JavaVersion.VERSION_17)
                    }
                } catch (_: Exception) {}
            }
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }

        tasks.withType<KotlinJvmCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
