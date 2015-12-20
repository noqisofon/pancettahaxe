package pancetta.logging;

import pancetta.linq;


public class LoggingService {

    /*!
     * ロギングサービスを初期化します。
     * \return void
     */
    public static function init() : Void {
        if ( __registry == null ) {
            __registry = new LogEngineRegistry();
        }

        if ( __dirty_config ) {
            loadConfig();
        }
        __dirty_config = false;
    }

    /*!
     * 設定などをリセットします。
     */
    public static function reset() {
        __registry     = null;
        __config       = new Map<String, LogConfiguration>();
        __dirty_config = true;
    }

    /*!
     * \return 既に同じキーに追加されていた場合は config を返す。それ以外は null。
     */
    public static function setConfig(key : String, config : LogConfiguration = null) : LogConfiguration {
        if ( __config.exists( key ) ) {
            var return_value = __config.get( key );
            
            if ( return_value == config ) {
                return return_value;
            }
        }
        __config.set( key, config );
        __dirty_config = true;

        return null;
    }

    /*!
     * 指定した名前のロガーエンジンを返します。
     */
    public static function getEngine(engineName : String) : Null<LogEngine> {
        init();

        if ( __registry.exists( engineName ) ) {
            return __registry.get( engineName );
        }
        return null;
    }

    /*!
     * ログレベルと共にメッセージを出力します。
     *
     * \param level   ログレベル。
     * \param message 書き込みたいメッセージ。
     * \param context コンテキスト。
     *
     * \return 書き込まれた場合、真。
     */
    public static function write(level : LogLevel, message : String, context : LoggingContext = null) : Bool {
        init();

        var logged = false;
        if ( context == null ) {
            context = new LoggingContext( [ "context" => [] ] );
        }

        for ( var systemName in __registry.loaded() ) {
            var logger = __registry.getLogger( systemName );
            var levels : Array<String> = [];
            var scopes : Array<String> = [];

            if ( logger is ILogger ) {
                levels = logger.levels;
                scopes = logger.scopes;
            }

            if ( scopes == null ) {
                scopes = [];
            }

            var correct_level = Enumerable.firstOrDefault( levels, (that) => that == level );
            var in_scope : Array[String] = [];
            if ( context.exists( "scope" ) ) {
                var context_scope = context.get( "scope" );
                if ( context_scope is Array[String] ) {
                    in_scope = ArrayLikeSet.intersect( context_scope, scopes );
                } 
            }

            if ( correct_level != null && in_scope.length > 0 ) {
                logger.log( level, message, context );
                logged = true;
            }
        }

        return logged;
    }

    /*!
     *
     */
    public static function emergency(message: String, context : LoggingContext = null) : Bool {
        return log( LogLevel.Emergency, message, context );
    }

    /*!
     * 設定をロードします。
     */
    protected static function loadConfig() : Void {
        for ( var key in __config.keys() ) {
            var properties = __config[key];

            if ( properties.exists( "engine" ) ) {
                properties["className"] = properties["engine"];
            }

            if ( __registry.exists( key ) ) {
                __registry.load( key, properties );
            }
        }
    }


    /*!
     * 設定が変更されると真になります。
     */
    protected static var __dirty_config : Bool = false;

    /*!
     * ログ設定
     */
    protected static var __config       : Map<String, LogConfiguration>;

    /*!
     * ログエンジンの集合？
     */
    private static var __registry       : LogEngineRegistry;
}
