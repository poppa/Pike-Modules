//! ActionScript syntax highlighter

//!
inherit "../Parser.pike";

public string title = "ActionScript";

protected multiset(string) delimiters = (<
  ",","(",")","{","}","[","]","-","+","*","%","/","=","\"","'",
  "~","!","&","|","<",">","?",":",";","." >);

protected mapping(string:multiset(string)) keywords = ([
  "keywords" : (<
    "if","while","with","var","void","typeof","new","delete","do","continue",
    "else","add","and","or","not","on","onClipEvent","le","lt","gt","for","in",
    "function","instanceof","ge","eq","break","#include","ne","return","try",
		"switch","default","case" >),

  "constants" : (<
    "ALT","BACKSPACE","CAPSLOCK","CONTROL","DELETEKEY","DOWN","END","ENTER",
    "ESCAPE","HOME","INSERT","LEFT","PGDN","PGUP","RIGHT","SHIFT","SPACE",
    "TAB","UP","CASEINSENSITIVE","DESCENDING","UNIQUESORT",
    "RETURNINDEXEDARRAY","NUMERIC","MAX_VALUE","MIN_VALUE","NEGATIVE_INFINITY",
    "NaN","POSITIVE_INFINITY","E","LN10","LN2","LOG10E","LOG2E","PI","SQRT1_2",
    "SQRT2","COMM","TALB","TBPM","TCOM","TCON","TCOP","TDAT","TDLY","TENC",
    "TEXT","TFLT","TIME","TIT1","TIT2","TIT3","TKEY","TLAN","TLEN","TMED",
    "TOAL","TOFN","TOLY","TOPE","TORY","TOWN","TPE1","TPE2","TPE3","TPE4",
    "TPOS","TPUB","TRCK","TRDA","TRSN","TRSO","TSIZ","TSRX","TSSE","TYER" >),

  "objects" : (<
    "Accessibility","Array","Boolean","Button","Camera","Color","ContextMenu",
    "ContextMenuItem","Customactions","Date","DateUTC","Error","Function",
    "Key","LoadVars","LocalConnection","Math","Microphone","MMExecute",
    "MovieClip","MovieClipLoader","Mouse","NetConnection","NetStream","Number",
    "Object","PrintJob","Selection","SharedObject","Sound","Stage","String",
    "StyleSheet","System","Systemcapabilities","Systemsecurity",
    "SystemuseCodepage","TextField","TextFormat","TextSnapshot","Video","Void",
    "XML","XMLNode","XMLSocket","Binding","ComponentMixins","DataAccessor",
    "DataHolder","DataSet","DataType","Delta","DeltaItem","DeltaPacket",
    "EndPoint","Log","PendingCall","RDBMSResolver","SOAPCall","TypedValue",
    "URL","WSDLURL","WebService","WebServiceConnector","XMLConnector",
    "XUpdateResolver","NetServices","NetConnection","RecordSet","Connection",
    "DataGlue","Fault","FaultEvent","Log","NetDebug","NetDebugConfig",
    "NetServices","PendingCall","RecordSet","RelayResponder",
    "RemotingConnector","Responder","ResultEvent","Service","NetConnection",
    "NetDebugConfig","NetDebug","Form","Slide","Accordion","Alert","Button",
    "CheckBox","ComboBox","DataGrid","DateChooser","DateField","Label","List",
    "Loader","MediaController","MediaDisplay","MediaPlayback","Menu","MenuBar",
    "NumericStepper","PopUpManager","ProgressBar","RadioButton" >),

  "methods" : (<
    "appendChild","attachMovie","attachSound","loadSound","attributes",
    "argumentscaller","argumentscallee","charAt","charCodeAt","childNodes",
    "clear","cloneNode","close","concat","connect","createElement",
    "createTextNode","docTypeDecl","status","duplicateMovieClip","firstChild",
    "getBounds","getBytesLoaded","getBytesTotal","getDate","getDay","getDepth",
    "getInstanceAtDepth","getNextHighestDepth","getFullYear","getHours",
    "getMilliseconds","getMinutes","getMonth","getNextDepth","getPan","getRGB",
    "getSeconds","getSWFVersion","getTime","getTimezoneOffset","getTransform",
    "getURL","getUTCDate","getUTCDay","getUTCFullYear","getUTCHours",
    "getUTCMilliseconds","getUTCMinutes","getUTCMonth","getUTCSeconds",
    "getVolume","getYear","globalToLocal","gotoAndPlay","gotoAndStop",
    "hasChildNodes","hitTest","indexOf","insertBefore","join","lastChild",
    "lastIndexOf","length","load","loadMovie","loadVariables","loaded",
    "localToGlobal","maxscroll","nextFrame","nextSibling","nodeName",
    "nodeType","nodeValue","onClose","onConnect","onLoad","onXML","parentNode",
    "parseXML","play","pop","prevFrame","previousSibling","push",
    "removeMovieClip","removeNode","reverse","scroll","send","sendAndLoad",
    "setDate","setFullYear","setHours","setMilliseconds","setMinutes",
    "setMonth","setPan","setRGB","setSeconds","setTime","setTransform",
    "setUTCDate","setUTCFullYear","setUTCHours","setUTCMilliseconds",
    "setUTCMinutes","setUTCMonth","setUTCSeconds","setVolume","setYear",
    "shift","slice","sort","sortOn","splice","split","start","startDrag",
    "stop","stopDrag","substr","substring","swapDepths","toLowerCase",
    "toString","prototype","__proto__","toUpperCase","unloadMovie",
    "getTextSnapshot","unshift","valueOf","xmlDecl","getAscii","getCode",
    "isDown","isToggled","abs","acos","asin","atan","atan2","ceil","cos","exp",
    "floor","log","max","min","pow","random","round","sin","sqrt","tan","hide",
    "show","getBeginIndex","getCaretIndex","getEndIndex","getFocus","setFocus",
    "setSelection","fromCharCode","addRequestHeader","attachMovie","call",
    "chr","duplicateMovieClip","escape","eval","false","fscommand","getBounds",
    "getBytesLoaded","getBytesTotal","getDepth","getProperty","getTimer",
    "getURL","getVersion","globalToLocal","gotoAndPlay","gotoAndStop",
    "hitTest","ifFrameLoaded","-Infinity","Infinity","int","isFinite","isNaN",
    "keyPress","length","loadMovie","loadMovieNum","loadVariables",
    "loadVariablesNum","localToGlobal","mbchr","mblength","mbord",
    "mbsubstring","newline","nextFrame","nextScene","null","ord","parseFloat",
    "parseInt","play","prevFrame","prevScene","print","printAsBitmap",
    "printNum","printAsBitmapNum","random","removeMovieClip","set",
    "setProperty","startDrag","stop","stopAllSounds","stopDrag","substring",
    "targetPath","tellTarget","this","toggleHighQuality","trace","true",
    "undefined","unescape","unloadMovie","unloadMovieNum","updateAfterEvent",
    "press","release","releaseOutside","rollOver","rollOut","dragOver",
    "dragOut","load","enterFrame","unload","mouseMove","mouseDown","mouseUp",
    "keyDown","keyUp","data","setInterval",
    "clearInterval","#initclip","#endinitclip","addProperty","registerClass",
    "enabled","useHandCursor","unwatch","watch","apply","call","_global",
    "super","autoSize","removeTextField","restrict","createTextField","html",
    "variable","hscroll","maxhscroll","border","background","wordWrap",
    "password","maxChars","multiline","textWidth","textHeight","selectable",
    "htmlText","bottomScroll","text","embedFonts","borderColor",
    "backgroundColor","textColor","font","size","color","url","target",
    "bullet","tabStops","bold","italic","underline","align","leftMargin",
    "rightMargin","indent","leading","replaceSel","replaceText",
    "getTextFormat","setTextFormat","getNewTextFormat","setNewTextFormat",
    "getTextExtent","getFontList","condenseWhite","mouseWheelEnabled",
    "getCount","setSelected","getSelected","getText","getSelectedText",
    "hitTestTextNearPos","findText","setSelectColor","addListener",
    "removeListener","focusEnabled","onPress","onRelease","onReleaseOutside",
    "onRollOver","onRollOut","onDragOver","onDragOut","onLoad","onUnload",
    "onMouseDown","onMouseMove","onMouseUp","onMouseWheel","onKeyDown",
    "onKeyUp","onData","onChanged","tabIndex","tabEnabled","tabChildren",
    "hitArea","onSetFocus","onKillFocus","setMask","isActive",
    "updateProperties","createEmptyMovieClip","beginFill","beginGradientFill",
    "moveTo","lineTo","curveTo","lineStyle","endFill","clear","_alpha",
    "_currentframe","_droptarget","_focusrect","_framesloaded","_height",
    "_highquality","_lockroot","_name","_quality","_rotation","_soundbuftime",
    "_target","_totalframes","_url","_width","_visible","_x","_xmouse",
    "_xscale","_y","_ymouse","_yscale","get","install","list","uninstall",
    "showMenu","scaleMode","align","width","height","onResize","exactSettings",
    "clear","contentType","createEmptyMovieClip","curveTo","height",
    "ignoreWhite","lineTo","moveTo","onEnterFrame","onScroller","trackAsMenu",
    "type","width","duration","position","onSoundComplete","onID3","id3",
    "artist","album","songtitle","year","genre","track","comment","hasAudio",
    "hasMP3","hasAudioEncoder","hasVideoEncoder","hasEmbeddedVideo",
    "screenResolutionX","screenResolutionY","screenDPI","screenColor",
    "pixelAspectRatio","hasAccessibility","input","isDebugger","language",
    "manufacturer","os","serverString","version","hasPrinting","playerType",
    "hasStreamingAudio","hasScreenBroadcast","hasScreenPlayback",
    "hasStreamingVideo","avHardwareDisable","localFileReadDisable",
    "windowlessDisable","name","message","class","extends","public","private",
    "static","interface","implements","import","dynamic","get","copy",
    "hideBuiltInItems","onSelect","builtInItems","save","zoom","quality",
    "loop","rewind","forward_back","print","customItems","caption",
    "separatorBefore","visible","attachVideo","bufferLength","bufferTime",
    "clear","close","connect","currentFps","height","onStatus","pause","play",
    "seek","setBufferTime","smoothing","time","bytesLoaded","bytesTotal",
    "start","addPage","send","paperWidth","paperHeight","pageWidth",
    "pageHeight","orientation","loadClip","unloadClip","getProgress",
    "onLoadStart","onLoadProgress","onLoadComplete","onLoadInit","onLoadError",
    "styleSheet","parse","parseCSS","getStyle","setStyle","getStyleNames",
    "transform","activityLevel","allowDomain","allowInsecureDomain",
    "attachAudio","attachVideo","bandwidth","bufferLength","bufferTime","call",
    "clear","close","connect","currentFps","data","deblocking","domain",
    "flush","fps","gain","get","getLocal","getRemote","getSize","height",
    "index","isConnected","keyFrameInterval","liveDelay","loopback",
    "motionLevel","motionTimeOut","menu","muted","name","names","onActivity",
    "onStatus","onSync","pause","play","publish","quality","rate",
    "receiveAudio","receiveVideo","seek","send","setBufferTime","setFps",
    "setGain","setKeyFrameInterval","setLoopback","setMode","setMotionLevel",
    "setQuality","setRate","setSilenceLevel","setUseEchoSuppression",
    "showSettings","setClipboard","silenceLevel","silenceTimeOut","smoothing",
    "time","useEchoSuppression","width","textFieldHeight","textFieldWidth",
    "ascent","descent","addDeltaItem","addEventListener","addFieldInfo",
    "addHeader","addItem","addItemAt","addSort","afterLoaded","applyUpdates",
    "argList","beforeApplyUpdates","calcFields","changesPending","clear",
    "component","concurrency","constant","createItem","curValue","currentItem",
    "data","dataProvider","delta","deltaPacket","deltaPacketChanged",
    "direction","disableEvents","doDecoding","doLazyDecoding","enableEvents",
    "encoder","event","execute","fieldInfo","filterFunc","filtered","find",
    "findFirst","findLast","first","formatter","getAnyTypedValue",
    "getAsBoolean","getAsNumber","getAsString","getCall","getChangeList",
    "getConfigInfo","getDeltaPacket","getField","getId","getItemByName",
    "getItemId","getIterator","getLength","getMessage","getOperation",
    "getOutputParameter","getOutputParameterByName","getOutputParameters",
    "getOutputValue","getOutputValues","getSource","getTimestamp",
    "getTransactionId","getTypedValue","hasNext","hasPrevious","hasSort",
    "ignoreWhite","includeDeltaPacketInfo","initComponent","isEmpty",
    "itemClassName","items","iteratorScrolled","kind","last","length",
    "loadFromSharedObj","locateById","location","logChanges","message",
    "modelChanged","multipleSimultaneousAllowed","mx.data.binding.Binding",
    "mx.data.binding.ComponentMixins","mx.data.binding.DataAccessor",
    "mx.data.binding.DataType","mx.data.binding.EndPoint",
    "mx.data.binding.TypedValue","mx.data.components.DataHolder",
    "mx.data.components.DataSet","mx.data.components.RDBMSResolver",
    "mx.data.components.WebServiceConnector","mx.data.components.XMLConnector",
    "mx.data.components.XUpdateResolver",
    "mx.data.components.datasetclasses.Delta",
    "mx.data.components.datasetclasses.DeltaItem",
    "mx.data.components.datasetclasses.DeltaPacket","mx.services.Log",
    "mx.services.PendingCall","mx.services.SOAPCall","mx.services.WebService",
    "myCall","name","newItem","newValue","next","nullValue","oldValue",
    "onFault","onLoad","onLog","onResult","operation","params","previous",
    "properties","property","readOnly","reconcileResults","reconcileUpdates",
    "refreshDestinations","refreshFromSources","removeAll",
    "removeEventListener","removeItem","removeItemAt","removeRange",
    "removeSort","request","resolveDelta","response","result","results",
    "saveToSharedObj","schema","selectedIndex","send","setAnyTypedValue",
    "setAsBoolean","setAsNumber","setAsString","setIterator","setRange",
    "setTypedValue","skip","status","suppressInvalidCalls","tableName",
    "trigger","typeName","updateMode","updatePacket","updateResults","useSort",
    "validateProperty","value","xupdatePacket","setDefaultGatewayUrl",
    "createGatewayConnection","getService","setCredentials","getColumnNames",
    "addView","addItem","addItemAt","getItemAt","getLength","removeAll",
    "removeItemAt","replaceItemAt","filter","setField","sort","sortItemsBy",
    "isLocal","isFullyPopulated","getNumberAvailable","setDeliveryMode",
    "trace","setDebugID","getDebugID","getDebugConfig","setDebug","getDebug",
    "addEventListener","addHeader","addItem","addItemAt","bindFormatFunction",
    "bindFormatStrings","call","clear","clone","close","columnNames","connect",
    "connection","contains","createGatewayConnection","description","detail",
    "editField","fault","faultcode","faultstring","filter","gatewayUrl",
    "getColumnNames","getConnection","getDebugConfig","getDebugId",
    "getEditingData","getHostUrl","getHttpUrl","getItemAt","getItemID",
    "getIterator","getLength","getLocalLength","getNumberAvailable",
    "getRemoteLength","getService","initialize","isEmpty","isFullyPopulated",
    "isLocal","items","length","methodName","multipleSimultaneousAllowed",
    "mx.data.components.RemotingConnector","mx.remoting.Connection",
    "mx.remoting.DataGlue","mx.remoting.NetServices","mx.remoting.PendingCall",
    "mx.remoting.RecordSet","mx.remoting.Service","mx.remoting.debug.NetDebug",
    "mx.remoting.debug.NetDebugConfig","mx.rpc.Fault","mx.rpc.FaultEvent",
    "mx.rpc.RelayResponder","mx.rpc.Responder","mx.rpc.ResultEvent",
    "mx.services.Log","name","onFault","onLog","onResult","params","password",
    "removeAll","removeEventListener","removeItemAt","replaceItemAt",
    "responder","result","results","send","serviceName","setCredentials",
    "setDebugId","setDefaultGatewayUrl","setDeliveryMode","setField",
    "setGatewayUrl","shareConnections","sort","sortItems","sortItemsBy",
    "status","suppressInvalidCalls","trace","trigger","type","userId",
    "addEventListener","allTransitionsInDone","allTransitionsOutDone",
    "autoKeyNav","autoLoad","bytesLoaded","bytesTotal","complete","content",
    "contentPath","createClassObject","createObject","currentChildSlide",
    "currentFocusedForm","currentFocusedScreen","currentFocusedSlide",
    "currentSlide","defaultKeyDownHandler","destroyObject","draw","enabled",
    "firstSlide","focusIn","focusOut","getChildAt","getChildForm",
    "getChildScreen","getChildSlide","getFocus","getStyle","gotoFirstSlide",
    "gotoLastSlide","gotoNextSlide","gotoPreviousSlide","gotoSlide",
    "handleEvent","hide","hideChild","indexInParent","indexInParentForm",
    "indexInParentSlide","invalidate","keyDown","keyUp","lastSlide","load",
    "mouseDown","mouseDownSomewhere","mouseMove","mouseOut","mouseOver",
    "mouseUp","mouseUpSomewhere","move","mx.screens.Form","mx.screens.Slide",
    "nextSlide","numChildForms","numChildScreens","numChildSlides",
    "numChildren","overlayChildren","parentForm","parentIsForm",
    "parentIsScreen","parentIsSlide","parentScreen","parentSlide",
    "percentLoaded","playHidden","previousSlide","progress","redraw","resize",
    "reveal","revealChild","rootForm","rootScreen","rootSlide","scaleContent",
    "scaleX","scaleY","setFocus","setSize","setStyle","unload","visible",
    "_accProps","activePlayControl","addColumn","addColumnAt","addCuePoint",
    "addEventListener","addItem","addItemAt","addMenu","addMenuAt",
    "addMenuItem","addMenuItemAt","addTreeNode","addTreeNodeAt","aspectRatio",
    "associateController","associateDisplay","autoLoad","autoPlay","autoSize",
    "backgroundStyle","buttonHeight","buttonStyleDeclaration","buttonWidth",
    "bytesLoaded","bytesTotal","cancelLabel","cellEdit","cellFocusIn",
    "cellFocusOut","cellPress","cellRenderer","change","click","close",
    "closeButton","columnCount","columnNames","columnStretch","complete",
    "content","contentPath","controlPlacement","controllerPolicy","conversion",
    "createChild","createClassObject","createMenu","createObject",
    "createPopUp","createSegment","cuePoint","cuePoints","data","dataProvider",
    "dateFormatter","dayNames","deletePopUp","destroyChildAt","destroyObject",
    "direction","disabledDays","disabledRanges","displayFull","displayNormal",
    "displayedMonth","displayedYear","doLayout","draw","dropdown",
    "dropdownWidth","editField","editable","enabled","enter","firstDayOfWeek",
    "firstVisibleNode","focusIn","focusOut","focusedCell","getBytesLoaded",
    "getBytesTotal","getChildAt","getColumnAt","getColumnIndex","getCuePoints",
    "getDisplayIndex","getFocus","getIsBranch","getIsOpen","getItemAt",
    "getMenuAt","getMenuEnabledAt","getMenuItemAt","getNodeDisplayedAt",
    "getStyle","getTreeNodeAt","groupName","hLineScrollSize","hPageScrollSize",
    "hPosition","hScrollPolicy","handleEvent","headerHeight","headerRelease",
    "hide","horizontal","html","icon","iconField","iconFunction",
    "indeterminate","indexOf","invalidate","itemRollOut","itemRollOver",
    "keyDown","keyUp","label","labelField","labelFunction","labelPlacement",
    "length","load","maxChars","maxHPosition","maxVPosition","maximum",
    "mediaType","menuHide","menuShow","messageStyleDeclaration","minimum",
    "mode","monthNames","mouseDownOutside","move","multipleSelection",
    "mx.containers.Accordion","mx.containers.ScrollPane",
    "mx.containers.Window","mx.controls.Alert","mx.controls.Button",
    "mx.controls.CheckBox","mx.controls.ComboBox","mx.controls.DataGrid",
    "mx.controls.DateChooser","mx.controls.DateField","mx.controls.Label",
    "mx.controls.List","mx.controls.Loader","mx.controls.MediaController",
    "mx.controls.MediaDisplay","mx.controls.MediaPlayback","mx.controls.Menu",
    "mx.controls.MenuBar","mx.controls.NumericStepper",
    "mx.controls.ProgressBar","mx.controls.RadioButton",
    "mx.controls.RadioButtonGroup","mx.controls.TextArea",
    "mx.controls.TextInput","mx.controls.Tree","mx.managers.PopUpManager",
    "nextValue","noLabel","nodeClose","nodeOpen","numChildren","okLabel",
    "open","password","pause","percentComplete","percentLoaded","play",
    "playheadChange","playheadTime","playing","preferredHeight",
    "preferredWidth","previousValue","progress","pullDown","redraw","refresh",
    "refreshPane","removeAll","removeAllColumns","removeAllCuePoints",
    "removeColumnAt","removeCuePoint","removeItemAt","removeMenuAt",
    "removeMenuItem","removeMenuItemAt","removeTreeNodeAt","replaceItemAt",
    "resizableColumns","resize","restrict","rowCount","rowHeight",
    "scaleContent","scaleX","scaleY","scroll","scrollDrag","selectable",
    "selectableRange","selected","selectedChild","selectedData","selectedDate",
    "selectedIndex","selectedIndices","selectedItem","selectedItems",
    "selectedNode","selectedNodes","selection","setFocus","setHPosition",
    "setIcon","setIsBranch","setIsOpen","setMedia","setMenuEnabledAt",
    "setMenuItemEnabled","setMenuItemSelected","setProgress","setPropertiesAt",
    "setSize","setStyle","setVPosition","show","showHeaders","showToday",
    "sortItems","sortItemsBy","sortableColumns","source","spaceColumnsEqually",
    "start","stepSize","stop","tabIndex","text","textField","title",
    "titleStyleDeclaration","toggle","totalTime","unload","vLineScrollSize",
    "vPageScrollSize","vPosition","vScrollPolicy","value","volume","wordWrap",
    "yesLabel","arrow","background","backgroundDisabled","check","darkshadow",
    "embedFonts","face","foregroundDisabled","focusRectOuter","focusRectInner",
    "highlight","highlight3D","radioDot","scrollTrack","selection",
    "selectionDisabled","selectionUnfocused","shadow","textAlign","textBold",
    "textColor","textDisabled","textFont","textIndent","textItalic",
    "textLeftMargin","textRightMargin","textSelected","textSize" >)
]);

private mapping(string:string) _colors = ([
  "classes"    : "#973",
  "objects"    : "#55C",
  "methods"    : "#C0A"
]);

protected array linecomments  = ({ "//" });

void create()
{
  colors += _colors;
  ::create();
}