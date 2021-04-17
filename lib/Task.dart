class Task {
  int taskId;
  String name;
  String description;
  String link;

  Task(this.taskId, this.name, this.description, this.link);
  Task.fromJson(Map<String, dynamic> json)
      : taskId = json['task_id'],
        name = json['name'],
        description = json['description'],
        link = json['link'];
}
