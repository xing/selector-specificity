require 'optparse' # cmdline options parser
require 'net/http' # net access
require 'uri' #converting url to uri

class Parser
   def initialize
     
     @errors_list = '';
     
      %%{
        # Ragel Code starts with machine name
        machine selector;

        # Ragel Ruby actions 
        include actions "includes/actions.rl";

        # CSS3 Selectors Module grammar
        include grammar "includes/grammar.rl";

        # Ragel starts with main, parses stylesheet with possible error action a_fail
        main := stylesheet $!a_fail %a_stylesheet_end;

        # Writes the scanner + parser code
        write data;

      }%%
   end
    
    def run(args)
      return "no input" unless args[:code] 
      
       # input as array "data" will be consumed by Ragel parser exec code

       # replaces CSS comments
       # http://www.w3.org/TR/css3-syntax/#tokenization
       # COMMENT 	::= 	"/*" [^*]* '*'+ ([^/] [^*]* '*'+)* "/"

      data = args[:code].gsub(/\/\*[^*]*\*+([^\/][^*]*\*+)*\//,'').unpack("c*")

      # Ragel writes initialization code, like
      # begin
      #	p ||= 0
      #	pe ||= data.length
      #	cs = selector_start
      #end
      %% write init;

      # More initialization:
      # saves the last correct position
      p_correct = 0;
      # set eof = pe to trigger Ragel EOF actions
      eof = pe;
      #count parse errors
      errors = 0;
      # to access EOF and be able to point after it, add an array element.
      data << 0; 


      #count selector specificity in the rulesets
      spec = Specificity.new;
      #count imported stylesheets
      imports = Counter.new;
      media = Counter.new;

      puts "\n\nRunning the state machine ...";

      # Ragel writes parser execution code
      %% write exec;

      puts "Parsing complete with #{errors} error(s).\n";
      puts args[:notes]
      puts  @errors_list;
      # parser specific variables
      # puts "Data pointer p: #{p}, Data End Pointer pe: #{pe}, Final state of the machine: #{cs}\n\n"
      puts "\na = IDs\nb = class selectors, attribute selectors, and pseudo-classes\nc = type selectors and pseudo-elements"
    end
    
 
end

class Specificity
  def initialize
    @a = @b = @c = @count = 0;
    @selector_a = @selector_b = @selector_c = 0;
    @ruleset = 0;
  end
  
  def add(abc)
    case abc
      when 'a'
        @a += 1; 
        @selector_a += 1;
      when 'b'
        @b += 1; 
        @selector_b += 1;
      when 'c'
        @c += 1; 
        @selector_c += 1; 
    end
  end
  
  def add_ruleset
    @ruleset +=1;
  end
  
  def selector_reset
    @selector_a = 0;
    @selector_b = 0;
    @selector_c = 0;
  end
  
  def selector_next
    @count += 1;
  end
  
  def selector_out
    print " a=#{@selector_a} b=#{@selector_b} c=#{@selector_c}"
  end
  
  def out
    perc = 1.0/@count;
    printf("Average specificity: a = %.3f b = %.3f c = %.3f [specificity/selector]\n", @a * perc, @b * perc, @c * perc);
    printf("Count: %d selectors in %d rulesets (average: %.3f [selectors/ruleset])\n", @count, @ruleset, @count.to_f/@ruleset);
  end
end

class Counter
  def initialize
    @count = 0;
  end
  
  def add
    @count += 1;
  end
 
  def note(string_true, string_false)
    if @count > 0
      "\n - " + @count.to_s() + string_true
    else
      if string_false != ''
        string_false
      end
    end
  end
end


class ArgumentsHash < Hash 
  
  def initialize(args) 
    
    self[:notes] = 'Note:'
    
    opts = OptionParser.new do |opts| 
      
      opts.banner = "Usage: ruby parser.rb [options]" 
      opts.separator( "Requests files from host" )
      
      opts.on('-f', '--file [STRING]', 'parses a file') do |str|
        if(File.file? str)
          self[:file] = str
          open(str) do |f| 
            self[:code] = f.read; 
          end
        else
          puts("\nError: cannot open #{str}")
          exit
        end
      end 
      
      opts.on( "-x", "--xhost [STRING]", 
              "parses from host" ) do |x|
        self[:file] = x;
        uri=URI.parse(URI.escape(x));
        puts uri
        
        if uri.scheme =="https" or uri.port == 443
         uri.scheme = "http"
         uri.port = "80"
         self[:notes] << "\n - switched URI scheme from https to http"
         
        end
        self[:file] = uri;
        response = Net::HTTP.get_response(uri)
        
          if response.is_a? Net::HTTPOK
            self[:code]= response.body 
          else
            puts("\nError: cannot open #{x} \n HTTP response code: #{response.code}")
            exit
          end
      end
      
      opts.on( "-i", "--input", "parses from STDIN until EOF (CTRL-D) is read.") do |i|
        # command-line arguments have been stripped from ARGV by OptionParser
        # the rest is in ARGF
        print "\nType in CSS code, quit with EOF (CTRL-D)\n>>>"
        self[:code] = ARGF.read;
        self[:file] = "STDIN";
      end
      
      opts.on_tail('-h', '--help', 'displays this help') do 
        puts opts 
        exit 
      end 
      
    end 
    
    begin
      opts.parse!(args)
    rescue OptionParser::InvalidOption
      puts "Error: invalid option; type -h for help"
    end

  end 
end

parser = Parser.new();
parser.run(ArgumentsHash.new(ARGV))
