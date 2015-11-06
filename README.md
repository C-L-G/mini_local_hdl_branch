# mini_local_hdl_branch
本地迷你的hdl代码版本控制

此为分布式的控制，区别于用一个软件平台来集中控制。

Linux，OS X默认已经安装有Ruby。

win需要自行安装，这也是我讨厌win的原因之一，win什么环境都没有。

文件15M左右，下载路径：https://www.ruby-lang.org/en/downloads/

===============================================================

文件说明：

HDLBranch.rb  主要代码块，也是运行代码，定义所有关于版本控制的方法


cfg_branch_XXXX 配置文件夹，用于保存上级的mater路径和下级的slave路径

|______XX.slave_path 保存下级的slave路径，文件每一行就是一个路径

|______XX.master_path 保存上级master的路径，文件每一行就是一个路径，只取最后一行，因为版本只能有一个master（父支），slave（子支）可以有多个

运行HDLBranch.rb 后的对话框如下：

--------------------------------

请选择：

1:从上级master 下载跟新

2:提交代码到上级master

3:同步下一级slave 分支代码

4:退出

--------------------------------

使用说明：

1、生成新的slave子分支：有两种方式

（1）、在slave文件夹中的XX.master_path加入master工程代码的路径，运行run.rb 选“1”

（2）、在master文件中的XX.slave_path加入slave的路径，运行run.rb 选 “3”

2、commit 向上提交更新

 运行HDLBranch.rb  选 “2”
 
3、从master下载更新

  运行HDLBranch.rb  选 “1”
  
4、更新同步所有的slave

  运行HDLBranch.rb  选 “3”
  
===============================================================  

注：

1、所有的HDL都会自动向下或向上拷贝，不要手动去复制

2、每次运行都会对所要处理的文件夹压缩备份，备份文件在cfg_branch_XXXX下

--@--Young--@--
