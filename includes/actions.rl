%%{
    machine actions;
    
    action a_universal {
        print " Universal";
    }

    action a_type_selector {
        print " Type";
        spec.add('c');
    }

    action a_pseudo_class {
        print " Pseudo-Class";
        spec.add('b');
    }
    action a_pseudo_element {
        print " Pseudo-Element";
        spec.add('c');
    }
    action a_attrib {
        print " Attribute";
        spec.add('b');
    }

    action a_class { 
        print " Class";
        spec.add('b');
    }

    action a_hash { 
        print " ID";
        spec.add('a');
    }
    
    action a_stylesheet_end {
      puts "\nFile: #{args[:file]}"
      spec.out();
      args[:notes] << media.note(" media queries may contain some of the counted selectors. These selectors add to the statistic.", ' ');
      args[:notes] << imports.note(" imported stylesheet(s) were not analyzed.", ' ');
    }
    
    action a_ruleset_end {
      puts "\n  end ruleset \"#{data.slice(p_correct, p-p_correct).pack("c*")}\"";
      spec.add_ruleset;
    }
    
    action a_mark_correct_p {
      p_correct = p;
    }
    
    action a_ruleset_begin {
      print "\n  begin ruleset"
    }
    
    
    action a_media_begin {
      print "\n begin media"
    }
    action a_media_end {
      puts " end media";
      media.add;
    }
    
    
    action a_selector_begin {
      print "\n    selector = {";
    }
    
    action a_selector_end {
      print " }";
      spec.selector_next;
      spec.selector_out;
      spec.selector_reset;
    }

    action a_import_begin {
       puts "\n begin import";
    }
    
    action a_import_end {
      imports.add();
      puts " end import";
    }
    
    action a_fontface_begin {
       puts "\n begin font-face";
    }
    action a_fontface_end {
      puts " end font-face";
    }
    
    action a_page_begin {
       puts "\n  begin page";
    }
    action a_page_end {
      puts "  end page";
    }
    action a_namespace_begin {
       puts "\n begin namespace";
    }
    action a_namespace_end {
      puts " end namespace";
    }
    

    action a_fail {
      errors = errors + 1;
      
      @tmperr = "\nParse error \##{errors}\n"
      @tmperr << data.slice(p_correct, 1+p-p_correct).pack("c*");
      @tmperr <<  "◀";
      if (p+25 < pe)
          @tmperr << data.slice(p+1, 25).pack("c*");
          @tmperr << "...\nResumed.\n";
      else
          @tmperr << data.slice(p+1, pe-p).pack("c*");
          @tmperr << "<End of File>"
      end
      print @tmperr
      @errors_list << (errors.to_s() + @tmperr)
      fhold;
      fgoto resume;
    }
    
}%%