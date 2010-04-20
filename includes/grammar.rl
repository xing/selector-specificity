%%{
    machine grammar;
    # http://www.w3.org/TR/css3-selectors/

    nonascii =  [^\0-\177];
    
    unicode =   /\\[0-9a-fA-F]{1,6}(\r\n|[ \n\r\t\f])?/;
    escape =    unicode | '\\' [^\n\r\f0-9a-fA-F];
  
    nmchar = (alnum | '_' | '-'); #|{nonascii}|{escape}
    name = nmchar+;

    nmstart = [_a-zA-Z]; #|{nonascii}|{escape}
    num = digit+ ('.' digit+)?; #[0-9]+|[0-9]*\.[0-9]+;
   
    COMMA = space* ',';
    DASHMATCH = "|=";
    GREATER = space* '>';
    
    HASH_neg = "#" name;
    HASH = "#" name > a_hash;
    ONLY = 'only'|'ONLY';
    AND = 'and'|'AND';
    NOT = 'not'|'NOT';
    IDENT = '-'? nmstart nmchar*;
    INCLUDES = "~=";
    NOTNEG = ":" NOT "(";

    NUMBER = num;
    PLUS = space* '+';
    PREFIXMATCH = "^=";
    S = space+;

    SUBSTRINGMATCH = "*=";
    SUFFIXMATCH = "$=";
    TILDE = space* '~';

    STRING =  /\'[^\']*\'/ | /\"[^\"]*\"/;
    
    #FUNCTION = IDENT "(";
    FUNCTION = ('nth-child'|'nth-last-child'|'nth-of-type'|'nth-last-of-type'|'lang') "("; 
    
    DIMENSION =  num IDENT;

    URL = ( /[!#$%&\*-~]/ | nonascii | unicode)*;
    
    URI = "url(" S* (STRING|URL) S* ")";
    
    CDO = "<!--";
    CDC = "-->";
    IMPORT_SYM = "@import";
    PAGE_SYM = "@page";
    MEDIA_SYM = "@media";
    FONT_FACE_SYM = "@font-face";
    CHARSET_SYM = "@charset";
    NAMESPACE_SYM = "@namespace";
    SCDOCDC = (S|CDO|CDC)*;

    element_name = IDENT;
    
    class_neg = '.' IDENT;
    class = '.' IDENT %a_class;


    namespace_prefix_general = IDENT;
    namespace_prefix = ( IDENT | '*' )? '|';

    universal_neg = namespace_prefix? '*';
    universal = namespace_prefix? '*' %a_universal;

    type_selector_neg = (namespace_prefix)? element_name;
    type_selector = (namespace_prefix)? element_name %a_type_selector;
    
    attrib_neg = '[' S* ( namespace_prefix )? IDENT S* ( (PREFIXMATCH | SUFFIXMATCH | SUBSTRINGMATCH | '=' | INCLUDES | DASHMATCH ) S* ( IDENT | STRING ) S* )? ']';
    attrib = '[' S* ( namespace_prefix )? IDENT S* ( (PREFIXMATCH | SUFFIXMATCH | SUBSTRINGMATCH | '=' | INCLUDES | DASHMATCH ) S* ( IDENT | STRING ) S* )? ']' %a_attrib;

    expression = ( (PLUS | '-' | DIMENSION | NUMBER | STRING | IDENT) S* )+;
    functional_pseudo = FUNCTION S* expression ')';
    
    pseudo_class = ':' ( 'root'|'first-child'|'last-child'|'first-of-type'|'last-of-type'|'only-child'|'only-of-type'|'empty'|'link'|'visited'|'active'|'hover'|'focus'|'target'|'enabled'|'disabled'|'checked' | functional_pseudo )  % a_pseudo_class;
    
    pseudo_element = ':' (':'?) ('first-line' | 'first-letter' | 'before' | 'after' ) % a_pseudo_element; 
    
    pseudo_neg = ':' ':'? ( IDENT | functional_pseudo );
    pseudo = pseudo_class | pseudo_element;
    
# _neg needed because selectors in a :not() are not counted in specificity computation 
    negation_arg = type_selector_neg | universal_neg | HASH_neg | class_neg | attrib_neg | pseudo_neg;
    negation = NOTNEG S* negation_arg S* ')';

    simple_selector_sequence = ((type_selector | universal ) ( HASH | class | attrib | pseudo | negation )*) | (HASH | class | attrib | pseudo | negation)+;

#S* ordered at the beginning, to catch the space as combinator 
    combinator = S+ | PLUS S* | GREATER S* | TILDE S*; 
    selector = simple_selector_sequence ( combinator simple_selector_sequence)* S*; #S* added to prevent matching of space before curly bracket as combinator
    selectors_group = (selector >a_selector_begin %a_selector_end) <: ( COMMA S* selector >a_selector_begin %a_selector_end)**;

    # the CSS3 declaration is complex
    #declaration_block = '{' S* declaration (';' S* declaration )* '}';
    declaration_block = /{[^{}]*}/;
    
    ruleset = (selectors_group declaration_block) >a_ruleset_begin %a_ruleset_end S* %a_mark_correct_p;

  
    namespace = (NAMESPACE_SYM %a_namespace_begin S* (namespace_prefix_general S*)? (STRING|URI) S* ';') %a_namespace_end S* %a_mark_correct_p;
    
    media_type = IDENT;
    media_feature = IDENT;
    #media_expression = '(' S* media_feature S* (':' S* expr)? ')' S*;  
    media_expression = '(' S* media_feature S* (':' S* /[^)]*/)? ')' S*;    
    media_query= (ONLY | NOT)? S* media_type S* (AND S* media_expression)* | media_expression (AND S* media_expression)*;
    media_query_list= media_query (',' S* media_query)*;
    media = (MEDIA_SYM %a_media_begin S* media_query_list '{' %a_mark_correct_p S* ruleset* '}') %a_media_end S* %a_mark_correct_p;
    
    imports = (IMPORT_SYM %a_import_begin S* (STRING|URI) S* media_query_list? S* STRING? S* ';') %a_import_end S* %a_mark_correct_p;
    
    font_face = (FONT_FACE_SYM %a_fontface_begin S* declaration_block) %a_fontface_end S* %a_mark_correct_p;

    #simplifies http://www.w3.org/TR/css3-page/
    pseudo_page = ':' IDENT;
    page = (PAGE_SYM  %a_page_begin S* IDENT? pseudo_page? S* declaration_block) %a_page_end S* %a_mark_correct_p;
    
    stylesheet = (CHARSET_SYM S* STRING S* ';' )? SCDOCDC (imports SCDOCDC)* (namespace SCDOCDC)* ((ruleset | page | media  | font_face) SCDOCDC)*;
    
    resume := ([^}]* '}' S*) @{p_correct = p; fgoto main;};
    
}%%