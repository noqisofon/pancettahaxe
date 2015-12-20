package pancetta.logging;


interface ILoggable {
    public function log(level : LogLevel, message : String) : Void;
}