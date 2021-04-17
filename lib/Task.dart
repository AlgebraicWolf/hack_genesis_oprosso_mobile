class TaskData {
  int taskId;
  String name;
  String description;
  String link;
  String pkgname;

  TaskData(this.taskId, this.name, this.description, this.link, this.pkgname);
  TaskData.fromJson(Map<String, dynamic> json)
      : taskId = int.parse(json['task_id']),
        name = json['name'],
        description = json['description'],
        link = json['file_ref'],
        pkgname = json['pkg_name'];
}
