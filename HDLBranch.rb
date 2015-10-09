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
        @slave_files = Dir["*.slave_path"]
        @master_files = Dir["*.master_path"]
        unless @slave_files.empty?
            @slave_files.each do |sf|
                File::open(sf) do |f|
                    while !f.eof?
                        l = f.readline.chomp
                        if File::directory? l
                            @slave_branch << File::expand_path(l)
                        end
                    end
                end
            end
        end
        unless @master_files.empty?
            @master_files.each do |mf|
                File::open(mf) do |f|
                    while !f.eof?
                        l = f.readline.chomp
                        if File::directory? l
                            @master_branch << File::expand_path(l)
                        end
                    end
                end
            end
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
        zip_file = File::join(path,"bak_#{time_spec}_#{find_bak_version(path)+1}.zip")
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
                fd =~ /^bak_\d{1,4}_\d{1,2}_\d{1,2}_(\d+)\.zip$/
                v = $1.to_i if $1 && v<$1.to_i
            end
        end
        v
    end


    def down_branch
        return "NOT MASTER BRANCH" if @master_branch.empty?
        create_zip_bak @cur_branch_path
        master_path = @master_branch.last
        mp = Dir::entries(master_path)
        mp = mp - %w(. ..)
        mp.each do |fitem|
            maser_item = File::join(master_path,fitem)
            slave_item = File::join(@cur_branch_path,fitem)
            cp_item maser_item,slave_item
        end
        "DOWN BRANCH SUCCESS"
    end

    def up_branch
        return "NOT MASTER BRANCH" if @master_branch.empty?
        master_path = @master_branch.last
        create_zip_bak master_path
        mp = Dir::entries(@cur_branch_path)
        mp = mp - %w(. ..)
        mp.each do |fitem|
            maser_item = File::join(master_path,fitem)
            slave_item = File::join(@cur_branch_path,fitem)
            cp_item slave_item,maser_item
        end
        "UP BRANCH SUCCESS"
    end

    def cp_item(source,target)
        if (File::file?(source) && source =~ /\w+\.([vV]|[sS][vV]|[vV][hH][dD])$/)
            FileUtils.cp source,target
        elsif File::directory?(source)
            Dir::mkdir(target) unless File::exist? target
            mp = Dir::entries(source)
            mp = mp - %w(. ..)
            mp.each do |fitem|
                maser_item = File::join(source,fitem)
                slave_item = File::join(target,fitem)
                cp_item maser_item,slave_item
            end
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
