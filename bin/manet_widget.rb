#!/usr/bin/ruby

require "../lib/netstat.rb"

class Table < Widget
  
  attr_writer :state
  attr_reader :selected
  attr_writer :block
 
  def initialize opts = {}
    
    @block=opts[:blk]||nil
    @selected=nil
    @state=:enabled
    @height=opts[:rows]
    @items=opts[:items] 
    @headers=opts[:headers]
    @columns=@headers.size
    mult = @items.size > @height ? 1:0
    debug(mult)
    nostroke
    @width=2
    @item=[]
    @headers.each { |x| @width+=(x[1]+1)  }
    nostroke
    fill red
    @top=opts[:top]
    @left=opts[:left]
    @rec=rect :top => 0, :left => 0, :width=>@width+mult*12+2, :height=>31*(@height+1)+4 
    @lefty=0  
    
    @header=flow do       
        @headers.each_with_index do |h,l|
          temp=(l==@headers.size-1 ? h[1]+12*mult : h[1])
          debug("#{l} -> #{temp}")
          flow :top=>2,:left=>@lefty+2,:width=>temp,:height=>29 do
            rect(:top=>0,:left=>1,:width=>temp,:height=>29, :fill=>lightgrey)
            p=para strong(h[0]), :top=>2,  :align=>'center'
            @lefty+=h[1]+1
          end
        end 
      end
     @flot1=stack :width=>@width+mult*12+2, :height=>31*(@height), :scroll=>true, :top=>33, :left=>1 do 
	@items.each_with_index do |it, i|
          inscription " "
          @item[i]=stack :width=>@width-1, :top=>31*i, :left=>1 do  
	    @lefty=0
            rr=[]
            #@columns.times do |ei|    
            @columns.times do |ei|
		rr[ei]=rect(:top=>1, :left=>@lefty+1, :width=>@headers[ei][1]-1,:height=>29, :fill=>white)
                it[ei]=" " if not it[ei] or it[ei]==""
                inscription strong(it[ei]), :top=>31*i+3, :left=>@lefty+2, :width=>@headers[ei][1]-1, :align=>'center' 	
		#inscription strong(it[ei]), :top=>31*i+3, :left=>@lefty+2, :width=>@headers[ei][1]-1, :align=>'center'
		@lefty+=@headers[ei][1]+1
            end
	    hover do
              if @state==:enabled
		      @item[i].contents.each{|x| x.style(:fill=>dimgray)}
	      end
            end
            leave do
              if @state==:enabled
                if @selected
                  if @selected==i
                    @item[i].contents.each{|x| x.style(:fill=>salmon)}
                  else
                    @item[i].contents.each{|x| x.style(:fill=>white)}
                  end
                else
                  @item[i].contents.each{|x| x.style(:fill=>white)}
                end
              end
            end
            click do
              if @state==:enabled
                if @selected
                  if @selected==i
                    @item[i].contents.each{|x| x.style(:fill=>white)}
                    @selected=nil
                  else
                    @item[@selected].contents.each{|x| x.style(:fill=>white)} 
                    @item[i].contents.each{|x| x.style(:fill=>salmon)}
                    @selected=i
                  end
                else
                  @item[i].contents.each{|x| x.style(:fill=>salmon)}
                  @selected=i
                end
                #@block.call 
			#@items[i] if @selected and @block 
			if @selected and @block 
					   b_adminroute = button "supprimer cette route #{@items[i][0].to_s}" do 	
					   	   route = Route.new(@items[i][0])
						   b_adminroute.click { alert(route.sup_route) }	
					   end
  					   b_adminroute.move(170,220)
			end
	      end  
            end         
          end
        end
      end
  end
    
  def set_selected(item_no)
    if @selected
      @selected=item_no
      @item[@selected].contents.each{|x| x.contents[1].style(:fill=>salmon)}
    end
  end
 
  def update_items(items, height=items.size)
    height=height if height<=items.size
    @rec.remove
    @header.remove
    @flot1.remove
    initialize(:top=>@top, :left=>@left,:rows=>height, :headers=>@headers, :items=>items, :blk=>@block)
  end 
end

Shoes.app :title => "Manet" do  
  @choix_machines = Choix_machines.new(%x[uname].chomp)
  @table_netstat_i=nil
  @t=nil
  @z=Proc.new {|x| alert x}
  @y=Proc.new {|x| alert "Hej: #{x}"}
  netstat =  ReaderNetstat.new

  stack :margin => [280, 0, 0, 0] do
  @netstat_titre = para "Visualiser les routes"
  end
  stack do
    @t= table(:top=>50, :left=>80, :rows=>5, :headers=>netstat.titre_colonne_netstat_rf,:items=>netstat.read_file,:blk=>@z)
  end
  
  b3 = button "Mettre à jour les routes" do
    @t.update_items(netstat.read_file, 5)
    @t.block=@y
  end

  b4 = button "Ajouter une nouvelle route" do
  	window :title => "Ajouter une route" do		
  		choix_machines = Choix_machines.new(%x[uname].chomp)
		stack :margin => [280, 0, 0, 0] do
		   @titre_ajout_route = para "Ajout d'une route"
		end
		para "route add"
		@choix_add_route = list_box :items => ["-host", "-net"] 
		
		@machine_depart = edit_line do
		end
	    unless choix_machines.choix_machines?
		@machine_destination = edit_line do 
		end
	    else
		    para "netmask "
		    @netmask = edit_line do
		    end

		    par "gw "
		    @gateway = edit_line do
		    end
	    end

		b_add_route = button "Enregister cette nouvelle route" do
			new_route = Route.new(@machine_depart.text)
			b_add_route.click { alert(choix_machines.choix_machines? ? new_route.add_route_linux(@choix_add_route.text,@netmask.text,@gateway.text) : new_route.add_route_bsd(@choix_add_route.text,@machine_destination.text)) }
		end
	end
  end
   
  stack do
  @table_netstat_i = table(:top=>50, :left=>80, :rows=>5, :headers=>netstat.titre_colonne_netstat_i, :items=>netstat.read_netstat_i, :blk=>@z) 
  end
  @table_netstat_i.hide
	b6=nil
	b5=nil   
  	b7=nil    
  b6 = button "Plus de détail sur les routes..." do 
	#@t.replace_headers(netstat.titre_colonne_netstat_i)
  	@table_netstat_i.show 
	@t.hide	
	@netstat_titre.replace "detail sur les routes"
	b3.hide
	#b5.show
	b6.hide
 	 b7 = button "Mettre à jour les détails des routes" do
  		@table_netstat_i.update_items(netstat.read_netstat_i,5)
  	 end
  	 b7.move(0,350)

     	b5 = button "Visualiser les routes" do
  		@t.show	
		@netstat_titre.replace "Liste des routes"
		b3.show
		b6.show
		b5.hide
		@table_netstat_i.hide
		b7.hide
      	 end
  	b5.move(360,450)
	b5.show
  end

  #b1.move(130,250)
  #b2.move(220,250)
  b3.move(100,350)
  b4.move(350,350)
  #b5.move(360,450)
  b6.move(130,450) 
  b5.move(360,450)
end
