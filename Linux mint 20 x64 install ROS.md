## Linux mint 20 x64 安装ROS

### 1(mint 20).设置源
sudo sh -c '. /etc/lsb-release && echo "deb http://mirrors.ustc.edu.cn/ros/ubuntu/  focal main" > /etc/apt/sources.list.d/ros-latest.list'  

sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 

### 1(UBUNTU 20.04).设置源
sudo sh -c '. /etc/lsb-release && echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list'  
### 或者选下面的中科大源
(sudo sh -c '. /etc/lsb-release && echo "deb http://mirrors.ustc.edu.cn/ros/ubuntu/ $DISTRIB_CODENAME main" > /etc/apt/sources.list.d/ros-latest.list')   

sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 


### 2.安装ROS noetic
sudo apt update  

sudo apt install ros-noetic-desktop-full  


### 3.添加环境变量
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc 
source ~/.bashrc 

### 4.安装ros所需工具
sudo apt install python3-rosinstall python3-rosinstall-generator python3-wstool build-essential python3-roslaunch


### 5.测试ROS是否安装成功，如果出现小乌龟代表安装成功：
rosrun turtlesim turtlesim_node



### -------------------------------------------


## 安装UR3-UR5支持



### 1.给ROS安装moveit
sudo apt install ros-noetic-moveit

### 2.下载UR仓库
git clone --depth 1 --branch melodic-devel https://github.com/ros-industrial/universal_robot.git

### 3.新建文件夹catkin_ws/src，把universal_robot文件夹拷贝到src目录下
mkdir catkin_ws  

cd catkin_ws  

mkdir src  

### 4.编译，如果编译不成功，记得先确认ROS有没有加载，只有成功加载ROS才能编译
catkin_make

### 5.编译完成后，进到编译后的目录，加载编译后的包
source devel/setup.bash

### 6.把这几句话添加到bashrc环境变量，一劳永逸，不用每次打开终端都输入同样的命令

echo "source /home/pl-ros/Documents/catkin_ws/devel/setup.bash" >> ~/.bashrc  
source ~/.bashrc 


### 7.安装依赖的几个包
sudo apt-get install ros-noetic-trac-ik-kinematics-plugin  

sudo apt-get install ros-noetic-effort-controllers  

sudo apt-get install ros-noetic-joint-trajectory-controller  

### 8.这时候可以执行测试了，打开3个终端，分别输入以下命令
roslaunch ur_gazebo ur5_bringup.launch  

roslaunch ur5_moveit_config moveit_planning_execution.launch sim:=true  

roslaunch ur5_moveit_config moveit_rviz.launch  
