###--@--Young--@--###

#Dir::chdir(File::dirname(File::expand_path(__FILE__)))
require "rubygems"
require "zip"
require "fileutils"
class HDLBranch
    attr_reader :master_branch,:slave_branch,:slave_files,:master_files
    def initialize(path=File::expand_path(__FILE__))
        @cur_branch_path = File::dirname path
        @slave_branch = []
        @master_branch = []
        @cfg_path = File::join(@cur_branch_path,"cfg_branch_#{File::basename(@cur_branch_path)}")
        Dir::mkdir(@cfg_path) unless File::exist?(@cfg_path)
        paths = Dir::entries(@cfg_path)
        paths = paths - %w(. ..)
        @slave_files = paths.select{|cf| (cf =~ /\w+\.slave_path$/) && File::file?(File::join(@cfg_path,cf))}
        @master_files = paths.select{|cf| (cf =~ /\w+\.master_path$/) && File::file?(File::join(@cfg_path,cf))}
        unless @slave_files.empty?
            @slave_files.each do |sf|
                File::open(File::join(@cfg_path,sf)) do |f|
                    while !f.eof?
                        l = f.readline.chomp.strip
                        if File::directory? l
                            @slave_branch << File::expand_path(l)
                        end
                    end
                end
            end
            @slave_branch.uniq!
        else
            slave_path_file = File::join(@cfg_path,"first.slave_path")
            File::open(slave_path_file,"w") {|f| f.puts " "}
        end
        unless @master_files.empty?
            @master_files.each do |mf|
                File::open(File::join(@cfg_path,mf)) do |f|
                    while !f.eof?
                        l = f.readline.chomp.strip
                        if File::directory? l
                            @master_branch << File::expand_path(l)
                        end
                    end
                end
            end
            @master_branch.uniq!
        else
            master_path_file = File::join(@cfg_path,"first.master_path")
            File::open(master_path_file,"w") {|f| f.puts " "}
        end
    end

    def collect_dir_path path
        return nil unless File::directory?(path)
        dir_c = []
        Dir.open(path) do |dir|
            dir.each do |pt|
                if File::directory?(pt) && /^\./ !~ pt
                    dir_c   << File::expand_path(pt)
                    dir_c   = dir_c | collect_dir_path(pt)
                end
            end
        end
        dir_c
    end

    def verilog_files(path=@cur_branch_path)
        collect_path(path,"file",/.+\.[vV]$/)
    end

    def systemverilog_fils(path=@cur_branch_path)
        collect_path(path,"file",/.+\.[sS][vV]$/)
    end

    def vhdl_files(path=@cur_branch_path)
        collect_path(path,"file",/.+\.[vV][hH][dD]$/)
    end

    def zip_files_path
        zip_files  = verilog_files|systemverilog_fils|vhdl_files
        zip_files.map do |e|
            e.gsub(Regexp.new("^#{@cur_branch_path}/"),"")
        end
    end


    def create_zip_bak(path)
        time = Time.new
        time_spec = "#{time.year}_#{time.month}_#{time.day}"
        cfg_path = File::join(path,"cfg_branch_#{File::basename(path)}")
        Dir::mkdir(cfg_path) unless File::exist?(cfg_path)
        zip_file = File::join(cfg_path,"bak_#{File::basename(@cur_branch_path)}#{time_spec}_#{find_bak_version(cfg_path)+1}.zip")
        Zip::File.open(zip_file,Zip::File::CREATE) do |zipfile|
            zip_files  = verilog_files(path)|systemverilog_fils(path)|vhdl_files(path)
            rep = Regexp.new("^#{path}/")
            zip_files.each do |zl|
                zipfile.add(zl.gsub(rep,""),zl)
            end
        end
    end

    def find_bak_version(path=@cur_branch_path)
        v = -1
        Dir.open(path) do |d|
            d.each do |fd|
                fd =~ /^bak_\w*?\d{1,4}_\d{1,2}_\d{1,2}_(\d+)\.zip$/
                v = $1.to_i if $1 && v<$1.to_i
            end
        end
        v
    end


    def download
        return "DONT HAVE MASTER BRANCH" if @master_branch.empty?
        master_path = @master_branch.last
        #mp = Dir::entries(master_path)
        #mp = mp - %w(. ..)
        #mp.each do |fitem|
        #    maser_item = File::join(master_path,fitem)
        #    slave_item = File::join(@cur_branch_path,fitem)
        #    cp_item maser_item,slave_item
        #end
        puts "===========#{'='*(master_path).length}"
        puts "UPDATE #{master_path} "
        puts "TO #{@cur_branch_path}"
        puts "===========#{'='*(@cur_branch_path).length}"
        create_zip_bak @cur_branch_path if cp_item master_path,@cur_branch_path
        update_path master_path,@cur_branch_path,"slave_path"
        update_script  @cur_branch_path,master_path
        puts "-----------#{'-'*(@cur_branch_path).length}"
        "DOWN BRANCH SUCCESS"
    end

    def commit_up
        return "DONT HAVE MASTER BRANCH" if @master_branch.empty?
        master_path = @master_branch.last
        #mp = Dir::entries(@cur_branch_path)
        #mp = mp - %w(. ..)
        #mp.each do |fitem|
        #    maser_item = File::join(master_path,fitem)
        #    slave_item = File::join(@cur_branch_path,fitem)
        #    cp_item slave_item,maser_item
        #end
        puts "===========#{'='*(@cur_branch_path).length}"
        puts "COMMIT #{@cur_branch_path}"
        puts "TO #{master_path}"
        puts "===========#{'='*(master_path).length}"
        create_zip_bak master_path if cp_item @cur_branch_path,master_path
        update_path master_path,@cur_branch_path,"slave_path"
        update_script  @cur_branch_path,master_path
        puts "-----------#{'-'*(master_path).length}"
        "UP BRANCH SUCCESS"
    end

    def sync_fork
        return "DONT HAVE SLAVE BRANCH" if @slave_branch.empty?
        @slave_branch.each do |sb|
            puts "===========#{'='*(@cur_branch_path).length}"
            puts "SYNC #{@cur_branch_path}"
            puts "TO #{sb}"
            puts "===========#{'='*(sb).length}"
            cp_item @cur_branch_path,sb
            #create_zip_bak sb if cp_item @cur_branch_path,sb
            update_path sb,@cur_branch_path,"master_path"
            update_script  @cur_branch_path,sb
            puts "-----------#{'-'*(sb).length}"
        end
        "SYNC FORK SUCCESS"
    end

    def update_path(target,source,ptype="slave_path")
        if ptype=="slave_path"
            rep = /.+\.slave_path$/
        elsif ptype=="master_path"
            rep = /.+\.master_path$/
        end
        target_cfg_path = File::join(target,"cfg_branch_#{File::basename(target)}")
        Dir::mkdir target_cfg_path unless File::exist? target_cfg_path
        files=collect_path(target_cfg_path,"file",rep)
        if files.empty?
            File.open(File::join(target_cfg_path,"file.#{ptype}"),"w") do |f|
                f.puts source
            end
            return nil
        end
        path_lines = []
        files.each do |path_f|
            File.open(path_f) do |pf|
                path_lines += pf.readlines
            end
        end
        path_lines.uniq!
        path_lines.map!{|pl|pl.chomp}
        path_lines = path_lines.select {|pl| File::exist?(pl) && File::directory?(pl)}
        path_lines.uniq!
        unless path_lines.include?(source)
            File.open(files.last,"a+") do |f|
                f.puts source
            end
        end
    end

    def update_script(source,target)
        rb_files = ["HDLBranch.rb","run.rb"]
        rb_files.each do |rf|
            tf = File::join(target,rf)
            sf = File::join(source,rf)
            FileUtils.cp(sf,tf)
        end
    end


    def cp_item(source,target)
        cp_exec=false
        if (File::file?(source) && source =~ /\w+\.([vV]|[sS][vV]|[vV][hH][dD]|qip)$/)
            if !File::exist?(target) || !FileUtils::cmp(source,target)
                FileUtils.cp source,target
                puts ">>>COPY>>>\t#{source}"
                puts ">>>>TO>>>>\t#{target}"
                cp_exec=true
            end
        elsif File::directory?(source)
            return nil if File::basename(source) =~ /^cfg_branch_\w/
            Dir::mkdir(target) unless File::exist? target
            mp = Dir::entries(source)
            mp = mp - %w(. ..)
            mp.each do |fitem|
                maser_item = File::join(source,fitem)
                slave_item = File::join(target,fitem)
                #tmp_cp_exec = cp_item(maser_item,slave_item)
                cp_exec= cp_item(maser_item,slave_item) || cp_exec
            end
            cp_exec
        end
    end


    def collect_path path,ptype,rep=/.+/
        #return nil unless File::directory?(path)
        dir_c = []
        Dir.open(path) do |dir|
            dir.each do |pt|
                type = File::ftype(File::join(path,pt))
                next if (type == "file" && rep !~ pt) || /^\./ =~ pt
                case(type)
                when "file"
                    dir_c   << File::join(path,pt) if ptype == "file"
                when "directory"
                    dir_c   << File::join(path,pt) if ptype == "directory"
                    dir_c   = dir_c | collect_path(File::join(path,pt),ptype,rep)
                else
                    nil
                end
            end
        end
        dir_c
    end

end
#### RUN SCRIPT #####
$: << File::dirname(File::expand_path(__FILE__))
require "HDLBranch"
require "io/console"

bl = HDLBranch.new

puts "请选择："
puts "1:从上级master 下载跟新"
puts "2:提交代码到上级master"
puts "3:同步下一级slave 分支代码"
puts "4:退出"

while word = gets.chomp
    if word =~ /^[1234]$/
        break
    else
        puts "请输入1-4"
    end
end

case word
when "1"
    puts bl.download
when "2"
    puts bl.commit_up
when "3"
    puts bl.sync_fork
else
    puts "--@--Young--@--"
end

#sleep(3)
puts "输入任意字符结束"
puts gets.chomp
#puts bl.sync_fork
#puts bl.zip_files_path
#bl.create_zip_bak
#p bl.slave_files
#p bl.master_files
#p Dir::entries File::dirname(File::expand_path(__FILE__))
