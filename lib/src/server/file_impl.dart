part of cargo_server;

class FileBackend extends Cargo {
  Completer _completer;
  final Logger log = new Logger('JsonStorage');
  String pathToStore;

  List<String> keys = new List<String>();

  Map map;

  FileBackend (String dir) : super._() {
    pathToStore = Platform.script.resolve(dir).toFilePath();
    _completer = new Completer();

    _exists(pathToStore);

    _readInKeys();
  }

  void _exists(dir) {
    try {
      if (!new Directory(dir).existsSync()) {
        log.severe("The '$dir' directory was not found.");
      }
    } on FileSystemException {
      log.severe("The '$dir' directory was not found.");
    }
  }

  dynamic getItemSync(String key) {
    if (keys.contains(key)) {
      var uriKey = new Uri.file(pathToStore).resolve("$key.json");
      var file = new File(uriKey.toFilePath());

      if (file.existsSync()) {
        // need to convert it to json!
        return JSON.decode(file.readAsStringSync());
      }
    }

    return null;
  }

  Future getItem(String key) {
    Completer complete = new Completer();

    if (keys.contains(key)) {
      var uriKey = new Uri.file(pathToStore).resolve("$key.json");
      var file = new File(uriKey.toFilePath());

      file.exists().then((bool exist) {
        // Need to convert it to json!
        file.readAsString().then((String fileValues) {
          complete.complete(JSON.decode(fileValues));
        });
      });
    } else {
      complete.complete();
    }

    return complete.future;
  }

  void setItem(String key, data) {
    var uriKey = new Uri.file(pathToStore).resolve("$key.json");
    var file = new File(uriKey.toFilePath());

    if (file.existsSync()) {
      _writeFile(file, key, data);
    } else {
      file.createSync();
      _writeFile(file, key, data);
    }
    if (!keys.contains(key)) {
      keys.add(key);
    }
    dispatch(key, data);
  }

  void _writeFile (File file, key, data) {
    file.writeAsStringSync(JSON.encode(data));
  }

  void removeItem(String key) {
    var uriKey = new Uri.file(pathToStore).resolve("$key.json");
    var file = new File(uriKey.toFilePath());

    file.delete().then((File file) {
      log.info("item $key deleted successfully");
    });
  }

  void clear() {
    Directory dir = new Directory(pathToStore);

    dir.list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
          var path = entity.path;
          if (path.indexOf(".json") > 1) {
            log.info("deleting $path");
            var file = new File(path);
            try {
              file.deleteSync();
            } on Exception catch(e) {
              print('Unknown exception: $e');
            }
          }
        });
    keys.clear();
  }

  int length() {
    return keys.length;
  }

  void _readInKeys() {
    Directory dir = new Directory(pathToStore);
        dir.list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
              var path = entity.path;
              
              if (path.indexOf(".json") > 1) {
                var fileName = path.split('\\').last; 
                fileName = fileName.replaceAll(".json", '');
                keys.add(fileName.toString());
              }
            }).onDone(() {
                _completer.complete();
            });
  }

  Future start() => _completer.future;
}
