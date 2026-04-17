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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- THÊM ĐOẠN NÀY ĐỂ FIX LỖI NAMESPACE TRÊN GITHUB ACTIONS ---
subprojects {
    afterEvaluate {
        // Kiểm tra xem project có phải là plugin Android không
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Nếu là ota_update và chưa có namespace thì tự động thêm vào
            if (project.name == "ota_update" && android.namespace == null) {
                android.namespace = "main.it.implicit.ota_update"
            }
            
            // Fix tổng quát cho các plugin cũ khác nếu cần
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }
        }
    }
}
