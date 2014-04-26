var fs = require('fs')

var TYPE_BLOCK = 0;
var TYPE_ARRAY = 1;

/*
Parses most of a KV file

Mostly copied from here:
https://github.com/Matheus28/KeyValue/blob/master/m28/keyvalue/KeyValue.hx
*/
function parseKV(data) {
    // Make sure we have some data to work with
    if(!data) return null;

    var tree = [{}];
    var treeType = [TYPE_BLOCK];
    var keys = [null];

    var i = 1;
    var line = 1;

    while(i < data.length) {
        var chr = data.charAt(i);

        if(chr == ' ' || chr == '\t') {
            // Ignore white space
        } else if(chr == '\n') {
            // We moved onto the next line
            line++;
            if(data.charAt(i+1) == '\r') i++;
        } else if(chr == '\r') {
            // We moved onto the next line
            line++;
            if(data.charAt(i+1) == '\n') i++;
        } else if(chr == '/') {
            if(data.charAt(i+1) == '/') {
                // We found a comment, ignore rest of the line
                while(++i < data.length) {
                    chr = data.charAt(i);

                    // Check for new line
                    if(chr == '\n' || chr == '\r') break;
                }

                // We are on a new line
                line++;

                // Move onto the next char
                i++;
            }
        } else if(chr == '"') {
            var resultString = '';
            i++;

            while(i < data.length) {
                chr = data.charAt(i);
                if(chr == '"') break;

                if(chr == '\n') {
                    // We moved onto the next line
                    line++;
                    if(data.charAt(i+1) == '\r') i++;
                } else if(chr == '\r') {
                    // We moved onto the next line
                    line++;
                    if(data.charAt(i+1) == '\n') i++;
                }else if(chr == '\\') {
                    i++;
                    // Gran the mext cjaracter
                    chr = data.charAt(i);

                    // Check for escaped characters
                    switch(chr) {
                        case '\\':chr = '\\'; break;
                        case '"': chr = '"'; break;
                        case '\'': chr = '\''; break;
                        case 'n': chr = '\n'; break;
                        case 'r': chr = '\r'; break;
                        default:
                            chr = '\\';
                            i--;
                        break;
                    }
                }

                resultString += chr;
                i++;
            }

            if (i == data.length || chr == '\n' || chr == '\r') throw new Error("Unterminated string at line " + line);

            if(treeType[treeType.length - 1] == TYPE_BLOCK){
                if (keys[keys.length - 1] == null) {
                    keys[keys.length - 1] = resultString;
                }else {
                    tree[tree.length - 1][keys[keys.length - 1]] = resultString;
                    keys[keys.length - 1] = null;
                }
            }else if (treeType[treeType.length - 1] == TYPE_ARRAY) {
                tree[tree.length - 1].push(resultString);
            }

            // Check if we need to reparse the character that ended this string
            if(chr != '"') --i;
        /*} else if(chr >= '0' && chr <= '9') {
            var startIndex = i++;
            while (i < data.length) {
                chr = data.charAt(i);
                if ((chr < '0' || chr > '9') && chr != '.' && chr != 'x') break;
                i++;
            }

            var resultNumber = parseInt(data.substr(startIndex, i - startIndex));
            if (resultNumber == null) throw new Error("Invalid number at line " + line + " (offset " + i + ")");

        */
        } else if(chr == '{') {
            if(treeType[treeType.length - 1] == TYPE_BLOCK){
                if (keys[keys.length - 1] == null) {
                    throw new Error("A block needs a key at line " + line + " (offset " + i + ")");
                }
            }

            tree.push({});
            treeType.push(TYPE_BLOCK);
            keys.push(null);
        } else if (chr == '}') {
            if (tree.length == 1) {
                throw new Error("Mismatching bracket at line " + line + " (offset " + i + ")");
            }
            if (treeType.pop() != TYPE_BLOCK) {
                throw new Error("Mismatching brackets at line " + line + " (offset " + i + ")");
            }
            keys.pop();
            var obj = tree.pop();

            if(treeType[treeType.length - 1] == TYPE_BLOCK){
                tree[tree.length - 1][keys[keys.length - 1]] = obj;
                keys[keys.length - 1] = null;
            }else {
                tree[tree.length - 1].push(obj);
            }
        } else {
            console.log("Unexpected character \"" + chr + "\" at line " + line + " (offset " + i + ")");

            // Skip to next line
            while(++i < data.length) {
                chr = data.charAt(i);

                // Check for new line
                if(chr == '\n' || chr == '\r') break;
            }

            // We are on a new line
            line++;

            // Move onto the next char
            i++;
        }

        i++;
    }

    if (tree.length != 1) {
        throw new Error("Missing brackets");
    }

    return tree[0];
}

var resDir = '../resource/';
var realResDir = '../../../resource/';

var langs = [
    'brazilian',
    'finnish',
    'french',
    'german',
    'greek',
    'hungarian',
    'nyx',
    'polish',
    'russian',
    'schinese',
    'spanish',
    'tchinese',
    'turkish'
]

fs.readFile(resDir+'addon_english.txt', 'utf16le', function(err, data) {
    if (err) throw err;

    console.log('Parsing english');
    var kv = parseKV(data);

    function fixKV(lang) {
        fs.readFile(resDir+'addon_'+lang+'.txt', 'utf16le', function(err, data2) {
            if (err) throw err;

            // Grab data for this language
            console.log('Parsing: '+lang);
            var kv2 = parseKV(data2);

            // Grab a new copy of the english data
            var newData = data;

            // Replace language header
            var key = 'Language'
            var realLang = kv.lang[key];
            var startPos = newData.indexOf(key)+key.length;
            var keyPos = newData.indexOf(realLang, startPos);
            newData = newData.substring(0, keyPos) + lang + newData.substring(keyPos+realLang.length);

            for(var key in kv.lang.Tokens) {
                var value = kv.lang.Tokens[key];
                value = value.replace(/\n/g, '\\n');
                value = value.replace(/\"/g, '\\"');
                value = value.replace(/\\/g, '\\\\');
                value = value.replace(/r/g, '\\\r');

                var startPos = newData.indexOf(key)+key.length;
                var keyPos = newData.indexOf(value, startPos);

                if(keyPos != -1) {
                    // See if this is already translated
                    var value2 = (kv2 && kv2.lang && kv2.lang.Tokens[key]);
                    if(!value2) {
                        // Translation would go here if I coded it

                        // Just grab the english value
                        value2 = value;
                    }

                    // Apply translated text
                    newData = newData.substring(0, keyPos) + value2 + newData.substring(keyPos+value.length);
                }
            }

            // Store new data
            fs.writeFile('Frota_'+lang+'.txt', newData, 'utf16le', function(err) {
                if(err) {
                    console.log(err);
                } else {
                    console.log(lang+' was updated!');
                }
            });
        });
    }

    // Fix every language
    for(var i=0; i<langs.length; i++) {
        fixKV(langs[i]);
    }
});

