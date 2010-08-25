"{{{1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:jsonOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "{{{2 Объявление переменных
    "{{{3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"load": {},
                \"plug": {},
                \"main": {},
                \"json": {},
                \"cache":{},
                \ "mng": {},
                \"comp": {},
            \}
    lockvar 1 s:F
    "{{{3 Глобальная переменная
    let s:g={}
    let s:g.load={}
    let s:g.c={}
    let s:g.c.options={"UsePython": ["bool", ""]}
    let s:g.defaultOptions={
                \"UsePython": 1,
            \}
    let s:g.pluginloaded=0
    let s:g.load.scriptfile=expand("<sfile>")
    let s:g.load.f=[["load", "cache.load", {  "model": "optional",
                \                          "required": [["file", "r"]],
                \                          "optional": [[["bool", ""],{},0]]}],
                \   ["loads", "json.loads", {  "model": "simple",
                \                           "required": [["type", type("")]]}],
                \   ["dump", "json.dump", {   "model": "simple",
                \                          "required": [["file", "w"],
                \                                       ["any", ""]]}],
                \   ["dumps", "json.dumps", {  "model": "simple",
                \                           "required": [["any", ""]]}],]
    "{{{3 Команды и функции
    " Определяет команды. Для значений ключей словаря см. :h :command. Если 
    " некоторому ключу «key» соответствует непустая строка «str», то в аргументы 
    " :command передаётся -key=str, иначе передаётся -key. Помимо ключей 
    " :command, в качестве ключа словаря также используется строка «func». Ключ 
    " «func» является обязательным и содержит функцию, которая будет вызвана при 
    " запуске команды (без префикса s:F.).
    let s:g.load.commands={
                \"Command": {
                \      "nargs": '1',
                \       "func": "mng.main",
                \   "complete": "custom,s:_complete",
                \},
            \}
    "{{{3 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "}}}2
    "{{{2 Регистрация дополнения
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin({
                \     "funcdict": s:F,
                \     "globdict": s:g,
                \      "oprefix": "json",
                \      "cprefix": "JSON",
                \          "sid": s:g.scriptid,
                \   "scriptfile": s:g.load.scriptfile,
                \     "commands": s:g.load.commands,
                \"dictfunctions": s:g.load.f,
                \   "apiversion": "0.0",
                \     "requires": [["load", '0.0'],
                \                  ["stuf", '0.0']],
            \})
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    let s:F.main.option=s:g.reginfo.functions.option
    finish
endif
"{{{1 Вторая загрузка
let s:g.pluginloaded=1
"{{{2 Чистка
unlet s:g.load
"{{{2 s:g.cache
let s:g.cache={}
"{{{2 Выводимые сообщения
if v:lang[:4]==#'ru_RU'
let s:g.p={
            \"emsg": {
            \       "r": "Файл недоступен для чтения",
            \       "w": "Файл недоступен для записи",
            \    "json": "Пакет «demjson» не найден",
            \   "rjson": "Не удалось прочитать файл с данными",
            \    "jstr": "Неверный JSON",
            \     "jse": "Строка в формате JSON должна заканчиваться ".
            \            "двойным штрихом («\"»)",
            \     "jsu": "Управляющая последовательность, ".
            \            "начинающаяся с «\u», должна заканчиваться ".
            \            "четырьмя шестнадцатиричными цифрами.",
            \    "jsie": "Неверная управляющая последовательность: ".
            \            "обратная косая черта должна следовать либо перед ".
            \            "символом «u» и четырьмя шестнадцатиричными символами, ".
            \            "либо перед одним из следующих символов: ".
            \            "«\», «/», «b», «f», «n», «r», «t»",
            \    "jobj": "Неверный объект формата JSON",
            \    "jkey": "Ключом словаря может быть только строка",
            \    "jdup": "Данный ключ уже использовался",
            \     "jdt": "Не найден символ двоеточия («:»)",
            \   "jcoma": "Отсутствует запятая",
            \     "joe": "Не найдена закрывающая фигурная скобка («}»)",
            \   "jlist": "Неправильный список формата JSON",
            \     "jle": "Не найдена закрывающая квадратная скобка («]»)",
            \    "uact": "Неизвестное действие",
            \},
            \"etype": {
            \     "value": "InvalidValue",
            \       "utf": "InvalidCharacter",
            \    "syntax": "SyntaxErr",
            \      "file": "BadFile",
            \},
            \"th": ["Файл", "Время последнего изменения"],
            \"emptycache": "Кэш пуст",
        \}
else
let s:g.p={
            \"emsg": {
            \       "r": "File not readable",
            \       "w": "File not writable",
            \    "json": "Demjson must be installed in your system",
            \   "rjson": "Failed to read JSON file",
            \    "jstr": "Invalid JSON string",
            \     "jse": "JSON string must end with “\"”",
            \     "jsu": "“\u” must be followed by four hex digits",
            \    "jsie": "Invalid escape: backslash must be followed by ".
            \            "“u” and four hex digits or ".
            \            "one of the following characters: ".
            \            "“\”, “/”, “b”, “f”, “n”, “r”, “t”",
            \    "jobj": "Invalid JSON object",
            \    "jkey": "Key in JSON object must be of a type “string”",
            \    "jdup": "Duplicate key",
            \     "jdt": "“:” not found",
            \   "jcoma": "Missing comma",
            \     "joe": "Object must end with “}”",
            \   "jlist": "Invalid JSON list",
            \     "jle": "List must end with “]”",
            \    "uact": "Uknown action",
            \},
            \"etype": {
            \     "value": "InvalidValue",
            \       "utf": "InvalidCharacter",
            \    "syntax": "SyntaxErr",
            \      "file": "BadFile",
            \},
            \"th": ["File", "Modification time"],
            \"emptycache": "Cache is empty",
        \}
endif
"{{{1 Вторая загрузка — функции
"{{{2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
"{{{2 main: eerror, destruct, option
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{2 json: dump, load, cload
"{{{3 s:g.json
"  values — значения соответствующих объектов
" escapes — список символов, которые можно экранировать и соответствующих им
"           «реальных» символов
" lstinner, objinner — значения по умолчанию для внутренних функций
"           json.getlst и json.getobj соответственно. Нужны, так как в функцию 
"           json.end необходимо передавать ссылки на переменные (все функции 
"           принадлежат парсеру JSON) (перенесены в начало соответствующих 
"           функций).
let s:g.json={
            \"values": {
            \    "null": "",
            \    "true": 1,
            \   "false": 0,
            \},
            \"escapes": {
            \   '"': '"',
            \   '\': '\',
            \   '/': '/',
            \   'b': "\b",
            \   'f': "\f",
            \   'n': "\n",
            \   'r': "\r",
            \   't': "\t",
            \},
        \}
" reg — регулярные выражения:
"  val — для получения объектов из json.values,
"  num — для выделения числа из строки,
"  str — для выделения строкового объекта JSON,
"  var — регулярное выражение для определения имени переменной, в которую
"        разрешено писать.
let s:g.json.reg={
            \"val": join(keys(s:g.json.values), '\|'),
            \"num": '^-\=\([1-9]\d*\|0\)\(\.\d\+\)\=\([eE][+\-]\=\d\+\)\=',
            \"str": '^"\([^\\"]\|\\\(u\x\{4}\|'.
            \       '['.escape(join(keys(s:g.json.escapes), ''), '\[]-').']'.
            \       '\)\)*"',
            \"var": '[gb]:[a-zA-Z_]\(\w\@<=\.\w\|\w\)*',
        \}
"{{{3 JSON dumper/vimscript
"{{{4 json.strstr: String->JSON
"{{{5 s:g.json.escrev
"  escrev — «обращённая» escapes, содержит соответствие реальных символов их
"           текстовым представлениям (под «реальным» здесь понимается то, что 
"           содержалось в памяти до перевода в JSON).
let s:g.json.escrev={}
call map(copy(s:g.json.escapes),
            \'extend(s:g.json.escrev, {v:val : "\\".v:key})')
"}}}5
function s:F.json.strstr(str)
    let selfname="json.strstr"
    "{{{5 Пустая строка
    if a:str==#""
        return "null"
    endif
    "{{{5 Объявление переменных
    let result='"'
    let idx=0
    let slen=len(a:str)
    "{{{5 Представление
    while idx<slen
        " Так мы получим следующий символ без диакритики (а на следующей 
        " итерации получим диакритику без символа).
        let chnr=char2nr(a:str[(idx):])
        let char=nr2char(chnr)
        let clen=len(char)
        let chkchar=a:str[(idx):(idx+clen-1)]
        if chkchar!=#char
            call s:F.main.eerror(selfname, "utf", 1, strtrans(chkchar))
        endif
        let idx+=clen
        if clen>1
            " На случай, если char2nr вернёт число, большее, чем 0xFFFF.
            if chnr<0x10000
                let result.=printf('\u%0.4x', chnr)
            " Следующий код производит корректный JSON, однако преобразование 
            " его обратно в Vim происходит некорректно (код производит 
            " суррогатную пару utf-16, обозначающую один символ, но результатом 
            " обратного преобразования является пара символов, не 
            " соответствующая стандарту UTF-8).
            elseif chnr<=0x10FFFF
                let U=chnr-0x10000
                let Uh=U/1024
                let W1=0xD800+Uh
                let W2=0xDC00+(U-(Uh*1024))
                let result.=printf('\u%0.4x\u%0.4x', W1, W2)
            else
                let result.=char
            endif
        elseif has_key(s:g.json.escrev, char)
            " Экранирование
            let result.=s:g.json.escrev[char]
        else
            let result.=char
        endif
    endwhile
    "}}}5
    return result.'"'
endfunction
"{{{4 json.strlst: List->JSON
function s:F.json.strlst(lst)
    return '['.join(map(copy(a:lst), 's:F.json.str(v:val)'), ',').']'
endfunction
"{{{4 json.strdct: Dictionary->JSON
function s:F.json.strdct(dct)
    return '{'.join(values(map(copy(a:dct),
                \'s:F.json.strstr(v:key).":".s:F.json.str(v:val)')),
                \',').'}'
endfunction
"{{{4 json.strfunc: Funcref->JSON(null)
" Представить функцию в виде JSON
function s:F.json.strfunc(func)
    return "null"
endfunction
"{{{4 json.str: *->JSON
function s:F.json.str(obj)
    return call(s:g.json.conv.tojstrfunc[type(a:obj)], [a:obj], {})
endfunction
"{{{4 json.vsdumps
function s:F.json.vsdumps(obj)
    return s:F.json.str(a:obj)
endfunction
"{{{4 s:g.json.conv.tojstrfunc
" Функции, представляющие произвольный объект. Отсортированы в соответствии 
" с типом объекта
let s:g.json.conv={}
let s:g.json.conv.tojstrfunc=[function("string"), s:F.json.strstr,
            \s:F.json.strfunc, s:F.json.strlst, s:F.json.strdct,
            \function("string")]
"{{{3 Парсер JSON на vimscript
"{{{4 json.getnum: JSON->(Number|Float)
function s:F.json.getnum(str)
    let numstr=matchstr(a:str, s:g.json.reg.num)
    if numstr=~?'e'
        " 0e0 → 0.0e0 (Vim не поддерживает запись чисел с плавающей запятой
        "              без десятичной точки)
        let numstr=substitute(numstr, '^-\=\d\+[eE]\@=', '\0.0', '')
    endif
    return      { "delta": len(numstr),
                \"result": eval(numstr),}
endfunction
"{{{4 json.getstr: JSON->String
function s:F.json.getstr(str)
    let selfname='json.getstr'
    let str=matchstr(a:str, s:g.json.reg.str)
    let delta=len(str)
    if !delta
        return s:F.main.eerror(selfname, 'syntax', ["jstr"])
    endif
    " Здесь необходимо добавить поддержку суррогатных пар.
    return      { "delta": delta,
                \"result": eval(str),}
endfunction
"{{{4 json.getobj: JSON->Dictionary
"{{{5 s:g.json.objinner
let s:g.json.objinner={
            \ "result": {},
            \  "delta": 1,
            \  "endch": '}',
            \"errargs": ["json.getobj", "syntax", ["jobj"], ["joe"]],
            \}
"}}}5
function s:F.json.getobj(str)
    "{{{5 Объявление переменных
    let selfname="json.getobj"
    let tlen=len(a:str)
    let inner=deepcopy(s:g.json.objinner)
    let inner.str=a:str
    "{{{5 Основной цикл
    while inner.delta<tlen
        "{{{6 Ключ
        " Ключ — строка, поэтому начинается с «"»
        let keystart=match(a:str, '^\_\s*\zs"', inner.delta)
        if keystart==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=keystart
        " Получить строку
        let lastret=s:F.json.getstr(a:str[(inner.delta):])
        if type(lastret)==type(0)
            return s:F.main.eerror(selfname, 'syntax', ["jobj"], ["jkey"])
        endif
        let inner.delta+=lastret.delta
        let key=lastret.result
        unlet lastret

        if has_key(inner.result, key)
            return s:F.main.eerror(selfname, 'syntax', ["jobj"], ["jdup"], key)
        endif
        "{{{6 Двоеточие
        let resstart=match(a:str, '^\_\s*\zs:', inner.delta)
        if resstart==-1
            return s:F.main.eerror(selfname, 'syntax', ["jobj"], ["jdt"])
        endif
        let inner.delta=resstart+1
        "{{{6 Получить значение
        let lastret=s:F.json.get(a:str[(inner.delta):])
        if type(lastret)==type(0)
            return lastret
        endif
        let inner.delta+=lastret.delta
        let inner.result[key]=lastret.result
        unlet lastret
        "{{{6 Запятая или конец объекта после значения
        let comma=match(a:str, '^\_\s*\zs,', inner.delta)
        if (comma)==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=(comma+1)
        "}}}6
    endwhile
    "}}}5
    return s:F.main.eerror(selfname, 'syntax', ["jobj"], ["joe"])
endfunction
"{{{4 json.getlst: JSON->List
"{{{5 s:g.json.lstinner
let s:g.json.lstinner={
            \ "result": [],
            \  "delta": 1,
            \  "endch": ']',
            \"errargs": ["json.getlst", "syntax", ["jlist"], ["jle"]],
            \}
"}}}5
function s:F.json.getlst(str)
    "{{{5 Объявление переменных
    let selfname="json.getlst"
    let tlen=len(a:str)
    let inner=deepcopy(s:g.json.lstinner)
    let inner.str=a:str
    "{{{5 Основной цикл
    while inner.delta<tlen
        "{{{6 Следующий объект
        let lastret=s:F.json.get(a:str[(inner.delta):])
        if type(lastret)==type(0)
            return s:F.json.end(inner)
        endif
        let inner.delta+=lastret.delta
        call add(inner.result, lastret.result)
        unlet lastret
        "{{{6 Запятая
        let comma=match(a:str, '^\_\s*\zs,', inner.delta)
        if (comma)==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=(comma+1)
        "}}}6
    endwhile
    "}}}5
    return s:F.main.eerror(selfname, 'syntax', ["jlist"], ["jle"])
endfunction
"{{{4 json.get: JSON->vim
" Получить объект произвольного типа из JSON
function s:F.json.get(str)
    "{{{5 Объявление переменных
    let selfname="json.get"
    let delta=match(a:str, '\_\s*\zs[\[{"tfn[:digit:].\-]')
    if delta==-1
        return 0
    endif
    let char=a:str[(delta)]
    "{{{5 Строка, список или объект
    if has_key(s:g.json.acts, char)
        let lastret=call(s:g.json.acts[char], [a:str[(delta):]], {})
        if type(lastret)==type({})
            let lastret.delta+=delta
        endif
        return lastret
    "{{{5 Число
    elseif char=~#'[[:digit:].\-]'
        let lastret=s:F.json.getnum(a:str[(delta):])
        if type(lastret)==type({})
            let lastret.delta+=delta
        endif
        return lastret
    "{{{5 Другое
    else
        let str=matchstr(a:str, s:g.json.reg.val, delta)
        let lstr=len(str)
        if !lstr
            return 0
        endif
        return      { "delta": delta+lstr,
                    \"result": s:g.json.values[str], }
    endif
    "}}}5
    return 0
endfunction
"{{{4 json.end
" Проверить, не конец ли это текущего объекта (словаря или списка)
function s:F.json.end(inner)
    let end=match(a:inner.str, '^\_\s*\zs'.a:inner.endch, a:inner.delta)
    if (end)!=-1
        return      { "delta": (end+1),
                    \"result": a:inner.result,}
    endif
    return call(s:F.main.eerror, a:inner.errargs, {})
endfunction
"{{{4 json.vsloads: JSON->vim, throws on error
function s:F.json.vsloads(str)
    let selfname="json.vsloads"
    let lastret=s:F.json.get(a:str)
    if type(lastret)==type(0)
        call s:F.main.eerror(selfname, "file", 1, ["rjson"])
    endif
    return lastret.result
endfunction
"{{{4 s:g.json.acts
let s:g.json.acts={
            \'"': s:F.json.getstr,
            \'[': s:F.json.getlst,
            \'{': s:F.json.getobj,
            \}
"{{{3 json.loads: JSON string->vim
" Загрузка переменной из JSON
function s:F.json.loads(str)
    let selfname="json.loads"
    "{{{4 Использовать ли Python?
    if !has("python") || !s:F.main.option("UsePython")
        return s:F.json.vsloads(a:str)
    endif
    "{{{4 null, true и false
    for O in keys(s:g.json.values)
        execute "let ".O."=s:g.json.values[O]"
    endfor
    "{{{4 Собственно, загрузка
    try
        python import vim
        python import demjson as json
        python jstr=json.decode(vim.eval("a:str"))
        " Simplejson не поддерживает UTF-8 символы выше 0x10FFFF, а demjson не 
        " сваливается с ошибкой, если встречается неверный UTF-8.
        " //Кроме того, demjson выдаёт UTF-8 строку, которую, если она содержит 
        " //не-ASCII символы, не удаётся засунуть в vim.command, тогда как 
        " //строка, выдаваемая simplejson не содержит не-ASCII символов.
        " Удаётся, через str(bytearray(jstr, "utf-8")) или через 
        " jstr.encode("ascii", "backslashreplace")
        " //И ещё, при попытке использовать в файле суррогатные пары получается 
        " //не тот результат, на который мы рассчитывали (simplejson).
        python vim.command("let tmp="+str(bytearray(jstr, "utf-8")))
        return tmp
    catch
        return s:F.json.vsloads(a:str)
    endtry
    "}}}4
endfunction
"{{{3 json.dumps: vim->JSON string
function s:F.json.dumps(what)
    let selfname="json.dumps"
    "{{{4 Проверка возможности записи
    "{{{4 Использовать ли Python?
    if !has("python") || !s:F.main.option("UsePython")
        return s:F.json.vsdumps(a:what)
    endif
    "{{{4 Собственно, выгрузка
    try
        python import vim
        python import demjson as json
        python var=vim.eval("a:what")
        " Simplejson не поддерживает UTF-8 символы выше 0x10FFFF, а demjson не 
        " сваливается с ошибкой, если встречается неверный UTF-8.
        python vim.command("let str='"+
                    \str(bytearray(json.encode(var), "utf-8")).replace("'", "''"))
        return str
    catch
        return s:F.json.vsdumps(a:what)
    endtry
    python fd.close()
    "}}}4
    return 1
endfunction
"{{{3 json.dump
function s:F.json.dump(fname, what)
    let selfname="json.dump"
    let fname=fnamemodify(a:fname, ':p')
    if !s:F.plug.stuf.iswriteable(fname)
        return s:F.main.eerror(selfname, "file", ["w"])
    endif
    let str=s:F.json.dumps(a:what)
    return writefile([str], fname)!=1
endfunction
"{{{2 cache: load, purge
"{{{3 cache.load: cached JSON file->vim
" Загрузить информацию из файла, если этот файл не загружался ранее или 
" изменился со времени последней загрузки. Иначе вернуть значение из кэша. При 
" наличии дополнительного аргумента, равного единице, игнорировать кэш.
function s:F.cache.load(fname, ...)
    let ftime=getftime(a:fname)
    if !(len(a:000) && a:000[0]) && has_key(s:g.cache, a:fname) &&
                \s:g.cache[a:fname][0]==ftime
        return s:g.cache[a:fname][1]
    endif
    let fname=fnamemodify(a:fname, ':p')
    if !filereadable(fname)
        call s:F.main.eerror(selfname, "file", 1, ["r"], fname)
    endif
    let str=s:F.plug.stuf.readfile(fname)
    let result=s:F.json.loads(str)
    let s:g.cache[a:fname]=[ftime, result]
    return result
endfunction
"{{{3 cache.show
function s:F.cache.show()
    if s:g.cache=={}
        echo s:g.p.emptycache
        return 1
    endif
    let header=(s:g.p.th)
    if exists("*strftime")
        let lines=values(map(copy(s:g.cache),
                    \'[v:key, strftime("%c", v:val[0])]'))
    else
        let lines=values(map(copy(s:g.cache),
                    \'[v:key, v:val[0]]'))
    endif
    return s:F.plug.stuf.printtable(header, lines)
endfunction
"{{{2 mng: main
"{{{3 mng.main
function s:F.mng.main(action)
    let selfname="mng.main"
    if a:action==#"showcache"
        return s:F.cache.show()
    elseif a:action==#"purgecache"
        let s:g.cache={}
        return 1
    endif
    return s:F.main.eerror(selfname, "value", ["uact"], a:action)
endfunction
"{{{2 comp: _complete
"{{{3 comp._complete
function s:F.comp._complete(...)
    return "showcache\npurgecache"
endfunction
"{{{1
lockvar! s:F
lockvar! s:g
unlockvar! s:g.cache
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

