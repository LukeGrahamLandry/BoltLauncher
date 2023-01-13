abstract class Problem {
  String get message;
}

class HashProblem extends Problem {
  String wanted;
  String got;
  String url;

  HashProblem(this.wanted, this.got, this.url);
  
  @override
  String get message => "Expected sha1=$wanted from $url but got sha1=$got";
}

class HttpProblem extends Problem {
  String errorMessage;
  String url;
  HttpProblem(this.errorMessage, this.url);
  
  @override
  String get message => "$errorMessage $url";
}

class VersionProblem extends Problem {
  @override
  String get message => "Unsupported minecraft & mod loader version combination";
}
