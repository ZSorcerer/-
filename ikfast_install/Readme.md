## 一.安装较新的openrave 0.130.0  
#### 1.首先安装ubuntu 20.04纯净版，不用更换源。  
#### 2.安装clash。运行clash后进入Service mode，打开TUN Mode 和Mixin，确保clash能在终端中运行。   
#### 3.在要开启代理的终端中输入下列命令来开启代理:  
```
export https_proxy=http://127.0.0.1:7890;  
export http_proxy=http://127.0.0.1:7890;  
export all_proxy=socks5://127.0.0.1:7890
```

#### 4.依次运行1,2,3,4,5_install_xxx.sh，等待安装完成。  
如果有哪个包安装失败，可以在cache-package目录下手动安装(注意，这里安装的是2023.sep.06的116fe9af5d5b8fe3196608ec93bc0dcc1a730fa1版本，这个版本是没有合并的一个分支，但是修正了和pybind 2.9不兼容的bug，不能安装最新版，最新版没有修正在pybind 2.9下 char* 和int不兼容的bug)。  

#### 5.设置openrave的环境变量(否则会找不到OPENRAVE_PLUGINS),将以下命令添加到 ~/.bashrc文件末尾，然后保存:  
```
sudo apt-get install vim  
sudo vim ~/.bashrc  
export OPENRAVE_PLUGINS=/usr/local/lib/openrave0.130-plugins  
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH  
```
#### 6. 让环境变量生效: 
```
source ~/.bashrc  
```
#### 7.安装ros noetic,安装方法参考另一个文件中的教程。  

#### 8.安装collada_urdf  
```
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH  
```

#### 9.修改openrave ikfast.py的一个已知bug:   
以root模式，用vscode或者sublime打开ikfast.py, 搜索tan(self.tvar)，然后修改为 tan(self.var)，这里多打了一个t。这个bug在几乎所有的版本都有，最新版修复了这个bug，但是没有和116fe9af5这个版本所修复的pybind 2.9下 char* 和int不兼容的bug进行合并。  


## 二.用ur5模型生成c++逆运动学求解器源码  

### 方案A.  
（这里需要注意，以下步骤生成的urdf文件转换成的dae文件，坐标系方向和关节数目有问题，会导致生成的c++代码文件体积巨大，而且求出的逆解值错误，原因目前还没有时间去排查，可能跟collada的坐标转换有关，需要手动编写xml文件来解决。）  

#### 1.下载UR5模型  
universal_robot：[https://github.com/ros-industrial/universal_robot](https://github.com/ros-industrial/universal_robot)  
本文只用到当中<universal_robot>/ur_description/urdf 目录下的模型ur5_joint_limited_robot.urdf.xacro  
注意，不能下载最新版，最新版目录中没有ur5_joint_limited_robot.urdf.xacro。最新版是ur5.xacro，模型是拆解的，会导致识别出的DH参数错误，需要找到有ur5_joint_limited_robot.urdf.xacro的旧版下载。  

#### 2.基于ur_description，创建或加入私有功能包  

以创建私有工作包为例，假设要创建的私有功能包名称是moveit_ws。  
```
mkdir ~p ~/moveit_ws/src  
cd ~/moveit_ws/src  
catkin_init_workspace  
cd ~/moveit_ws  
catkin_make  
source devel/setup.bash  
```
catkin_make成功后，把目录<universal_robot>/ur_description复制到~/moveit_ws/src，再重新catkin_make  

#### 3.xacro格式转换成urdf格式  
```
cd ~/moveit_ws/src/ur_description/urdf  
rosrun xacro xacro --inorder -o ur5.urdf ur5_joint_limited_robot.urdf.xacro  
```
转换成功后，可执行“urdf_to_graphiz ur5.urdf”生成ur5.pdf，打开pdf查看该模型整体结构。  

#### 4.urdf格式转换成dae格式  
```
rosrun collada_urdf urdf_to_collada ur5.urdf ur5.dae  
```
#### 5.设置精度  
这一步设置的是模型的精度，用来识别DH参数，不是ikfast的计算精度。这里设为5足够了，但是我认为这里也有问题，实际模型的精度要参考官方的DH参数并且手动修改，因为某些关节的小数点后没有这么高精度，有些可能超过5位，需要参考官方的DH值进行修改:  
[https://www.universal-robots.com/articles/ur/application-installation/dh-parameters-for-calculations-of-kinematics-and-dynamics/](https://www.universal-robots.com/articles/ur/application-installation/dh-parameters-for-calculations-of-kinematics-and-dynamics/)  

```
export IKFAST_PRECISION="5"  
rosrun moveit_kinematics round_collada_numbers.py ur5.dae ur5.dae "$IKFAST_PRECISION"  
```
#### 6.查看关节数据  
```
openrave-robot.py ur5.dae --info links  
```
#### 7.查看三维模型。  
这里能检查到dae文件的坐标系和UR机器人示教器上的base坐标系方向相反，除此之外姿态坐标也不一致，不能只简单的更改dae文件的base坐标。  
```
openrave ur5.dae  
```
#### 8.生成ikfast c++文件（这里生成的有问题，除了下面验证的一组，计算其它很多姿态都是错误的）:  
```
sudo python `openrave-config --python-dir`/openravepy/_openravepy_/ikfast.py --robot=ur5.dae --iktype=transform6d --baselink=0 --eelink=9 --savefile=$(pwd)/ikfast61.cpp  
```
这里可能会报错，提示from . import xxx错误，可能是新版的某个python包导致相对路径识别有问题，如果报错直接定位到ikfast.py的目录，修改这个文件，定位到错误行，把from . 删掉，直接import xxx就可以了。  
如果解决了上面的问题，还有其它报错，说明openrave安装失败或者某些依赖包安装失败，如果不能手动修复，需要重装系统再次重新安装。  
#### 9.使用ikfast61.cpp求逆解  
(lapack也可以更换成并行版本的OpenBlas，但是我试过，速度没有明显提升，耗时主要在ikfast的迭代环节，这部分没有用并行实现)  
```
cp /usr/local/lib/python2.7/dist-packages/openravepy/_openravepy_/ikfast.h .  
g++ ikfast61.cpp -o ikfast -llapack -std=c++11  
```
注：  

IKFast 算法依赖于LAPACK（Linear Algebra PACKag）库，所以编译的时候要链接 liblapack.so 库；  
输入为 3x4 矩阵（rotation 3x3， translation 3x1）
```
r00 r01 r02 t1 r10 r11 r12 t2 r20 r21 r22 t3  
```
转换成 3x4 矩阵：  
```
r00  r01  r02  t1  
r10  r11  r12  t2  
r20  r21  r22  t3  
```
#### 10.生成 8 组解  
```
./ikfast 0.04071115 -0.99870914 0.03037599 0.4720009 -0.99874455 -0.04156303 -0.02796067 0.12648243 0.0291871 -0.02919955 -0.99914742 0.43451169  
```
![此图展示的是生成的8组解的结果](https://github.com/rdiankov/openrave/assets/28340764/0c68a147-e49e-4e77-9b9e-4aca38f04ba8)  
如果结果和上图不一致，则说明openrave的安装失败，或者xacro、URDF、dae模型的参数或结构是错误的。
#### 11.用正向运动学方程进行验证  
```
#include <iostream>
#include <chrono>
#include <string>
#include <Eigen/Dense> // For most core Eigen functionalities

Eigen::Isometry3d chain_getSegment_pose(const Eigen::Vector3d& xyz, const Eigen::Vector3d& rpy, const Eigen::Vector3d& axis_tag_xyz, double angle)
{
	Eigen::AngleAxisd rollAngle(Eigen::AngleAxisd(rpy(0), Eigen::Vector3d::UnitX()));
	Eigen::AngleAxisd pitchAngle(Eigen::AngleAxisd(rpy(1), Eigen::Vector3d::UnitY()));
	Eigen::AngleAxisd yawAngle(Eigen::AngleAxisd(rpy(2), Eigen::Vector3d::UnitZ()));

	Eigen::Isometry3d F_parent_jnt = Eigen::Isometry3d::Identity();
	F_parent_jnt.rotate(yawAngle * pitchAngle * rollAngle);
	Eigen::Vector3d _axis = F_parent_jnt.rotation() * axis_tag_xyz;
	Eigen::Vector3d axis = _axis / _axis.norm();

	Eigen::Isometry3d joint_pose = Eigen::Isometry3d::Identity();
	joint_pose.rotate(Eigen::AngleAxisd(angle, axis));
	joint_pose.pretranslate(xyz);

	Eigen::Isometry3d f_tip = Eigen::Isometry3d::Identity();
	f_tip.rotate(F_parent_jnt.rotation());

	Eigen::Isometry3d result = joint_pose * f_tip;
	return result;
}

void verify_ur5()
{
	Eigen::Isometry3d result;
	//double angle0[6] = { -2.508279331875612, -3.013057342196758, 1.224580428339185, 1.736242820305415, 0.593205998702227, 0.072539035191919 };
	double angle0[6] = { 0,0,0,0,0,0 };
	std::vector<double*> angles;
	angles.push_back(angle0);
	int at = 0;
	for (std::vector<double*>::const_iterator it = angles.begin(); it != angles.end(); ++it, at++) {
		double* angle = *it;
		result = Eigen::Isometry3d::Identity();
		// SDL_Log("Joint: shoulder_pan_joint");
		Eigen::Vector3d rpy = Eigen::Vector3d(0.0, 0.0, 0.0);
		Eigen::Vector3d xyz = Eigen::Vector3d(0.0, 0.0, 0.089159);
		Eigen::Vector3d axis_tag_xyz = Eigen::Vector3d(0, 0, 1);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[0]);
		// SDL_Log("Joint: shoulder_lift_joint");
		rpy = Eigen::Vector3d(0.0, 1.5707963267948966, 0.0);
		xyz = Eigen::Vector3d(0.0, 0.13585, 0.0);
		axis_tag_xyz = Eigen::Vector3d(0, 1, 0);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[1]);
		// SDL_Log("Joint: elbow_joint");
		rpy = Eigen::Vector3d(0.0, 0.0, 0.0);
		xyz = Eigen::Vector3d(0.0, -0.1197, 0.425);
		axis_tag_xyz = Eigen::Vector3d(0, 1, 0);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[2]);
		// SDL_Log("Joint: wrist_1_joint");
		rpy = Eigen::Vector3d(0.0, 1.5707963267948966, 0.0);
		xyz = Eigen::Vector3d(0.0, 0.0, 0.39225);
		axis_tag_xyz = Eigen::Vector3d(0, 1, 0);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[3]);
		// SDL_Log("Joint: wrist_2_joint");
		rpy = Eigen::Vector3d(0.0, 0.0, 0.0);
		xyz = Eigen::Vector3d(0.0, 0.093, 0.0);
		axis_tag_xyz = Eigen::Vector3d(0, 0, 1);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[4]);
		// SDL_Log("Joint: wrist_3_joint");
		rpy = Eigen::Vector3d(0.0, 0.0, 0.0);
		xyz = Eigen::Vector3d(0.0, 0.0, 0.09465);
		axis_tag_xyz = Eigen::Vector3d(0, 1, 0);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, angle[5]);
		// SDL_Log("Joint: ee_fixed_joint");
		rpy = Eigen::Vector3d(0.0, 0.0, 1.5707963267948966);
		xyz = Eigen::Vector3d(0.0, 0.0823, 0.0);
		axis_tag_xyz = Eigen::Vector3d(0, 0, 1);
		result = result * chain_getSegment_pose(xyz, rpy, axis_tag_xyz, 0);

		std::stringstream ss;
		ss << "total result's matrix = \n";
		ss << result.matrix();
		printf("%s", ss.str().c_str());
	}
}






int main()
{
    verify_ur5();
    return 0;
}
```
#### 12.生成moveit_ikfast_plugin功能包  
```
cd ~/moveit_ws/src  
export MOVEIT_IK_PLUGIN_PKG="moveit_ikfast_plugin"  
catkin_create_pkg "$MOVEIT_IK_PLUGIN_PKG  
```
上面语句的功能是在\~/moveit_ws/src 添加功能包moveit_ikfast_plugin。下面填充功能包内容，假设成功world-->ee_link的规划组叫“robot_arm”。  
```
cd \~/moveit_ws/src/moveit_ikfast_plugin   
export MYROBOT_NAME="ur5"  
export PLANNING_GROUP="robot_arm"  
export IKFAST_OUTPUT_PATH=\~/moveit_ws/src/ur_description/urdf/ikfast61.cpp  
rosrun moveit_kinematics create_ikfast_moveit_plugin.py "$MYROBOT_NAME" "$PLANNING_GROUP" "$MOVEIT_IK_PLUGIN_PKG" "world" "ee_link" "$IKFAST_OUTPUT_PATH"  
```
成功后，会在\~/moveit_ws/src/moveit_ikfast_plugin/src 生成两个文件。  
1. **_ur5_robot_arm_ikfast_moveit_plugin.cpp_**：创建一个可用在moveit的，针对“ur5”模型、“robot_arm”规划组，派生于KinematicsBase的运动学求解器。  
2. **_ur5_robot_arm_ikfast_solver.cpp_**：它的内容就是ikfast61.cpp。  
执行catkin_make后，“rospack find moveit_ikfast_plugin”可得到moveit_ikfast_plugin功能包的有效路径。  

### 方案B.  
#### 1.使用ikfastpy项目  
这个仓库是用手动编写的xml文件导入openrave进行DH参数的识别，经过验证，这个xml文件计算出来的正解和逆解均正确而且精度很高。这个xml文件简单清晰，可以方便手动修改。  
```
git clone https://github.com/andyzeng/ikfastpy.git  
```
#### 2.安装Cython  
```
sudo pip install Cython  
```
#### 3.编译并安装ikfastpy包
```
cd ikfastpy  
sudo python setup.py build_ext --inplace  
```
#### 4.验证正解和逆解的结果  
```
python demo.py  
```
#### 5.重新生成ikfast.cpp  
这个包用的是旧版的ikfast.cpp，是该作者自己生成的，我们可以用前面安装好的openrave 2023 sep.06版，生成较新的ikfast，正常情况下，5分钟左右就可以生成成功，生成的ikfast.cpp的大小在500kb附近，如果超过1MB，可能模型或者参数配置有问题，不仅生成慢(大概20分钟)，而且会导致逆解变慢以及计算错误：  
```
python `openrave-config --python-dir`/openravepy/_openravepy_/ikfast.py --robot=ur5.robot.xml --iktype=transform6d --baselink=0 --eelink=6 --savefile=ikfast61.cpp --maxcasedepth 1  
```
#### 6.把新版的ikfast.h拷贝到当前目录下:
```
cp /usr/local/lib/python2.7/dist-packages/openravepy/_openravepy_/ikfast.h .  
```
#### 7.生成完毕后，再次验证正解和逆解的结果 
```
python demo.py  
```
#### 8.编译windows下的.lib文件。  
需要首先安装intel iFortran 编译器，在windows下手动编译lapack和blas的静态库，然后使用上面的ikfast.h和ikfast.cpp 编译出ikfast.lib，就可以导入自己的程序调用函数了。  
注意，编译的时候，iFortran的符号命名下划线需要在配置中修改，ikfast.cpp extern C这部分的下划线以及全文中同名部分的下划线也要去掉。还有一些#define的参数要修改，才能成功编译出ikfast.lib。  
#### 9. 注意UR机器人默认DH参数和校准参数。  
ikfast是按照UR机器人理论值的DH参数求出的解析形式的封闭解，需要每个旋转轴两两正交并且交于一点。但是UR机器人(其它协作机器人也同理)出厂的时候会校准DH参数，这会使得两个关节的旋转轴并不一定相交，两个旋转轴一定会有间距(机械安装也做不到正交的旋转轴完全交于一点)，这样做的目的是提高UR机器人的绝对定位精度，但是这会使得ikfast求出的逆解和UR机器人的姿态不一致，有些位置的坐标误差会有5~8个mm，关节角的误差会有3~5°。 如果要让ikfast的结果和UR机器人的姿态完全一致，目前没有完美的解决方案，目前折衷的办法是修改UR机器人示教器U盘中/root目录下的calibration.conf文件，把校准的DH参数的变化量全部设为0，这样就可以让UR机器人的姿态严格按照理论值进行计算。这样做不会影响重复定位精度，但是会影响绝对定位精度。对于遥操作来说只要重复定位精度高就行了，如果后续需要重新用到绝对定位精度，则需要还原出厂校准的calibration.conf文件的值。 因此，如果修改calibration.conf，需要提前做好备份。

还有一种方法是使用数值解，目前数值解求解速度最快的是Track-ik, UR5机器人使用Track-ik求解时间差不多400~500微秒，而且Track-ik可以使用出厂校准后的DH参数进行数值求解(相关资料可以在[https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/issues/
226](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/issues/
226) 找到)，但是需要依赖ROS。
