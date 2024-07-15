### 首先安装linux mint 20 或者ubuntu 20.04， 确保python的版本是python3.8 

```
1. git clone https://github.com/PyMesh/PyMesh.git
2. cd PyMesh
3. git submodule update --init
4. sudo apt-get install \
    libeigen3-dev \
    libgmp-dev \
    libgmpxx4ldbl \
    libmpfr-dev \
    libboost-dev \
    libboost-thread-dev \
    libtbb-dev \
    python3-dev
5. sudo apt install g++
sudo apt install python3-pip
sudo apt install cmake
sudo apt install zip
```

```
6.pip install -r $PYMESH_PATH/python/requirements.txt    （$PYMESH_PATH - pymesh的路径）
```

```
7.
pip install pybind11
sudo apt install pybind11-dev
sudo apt install python3-pybind11
sudo apt-get install libboost-all-dev

8.
cd $PYMESH_PATH/third_party
build.py all

9.
cd $PYMESH_PATH
mkdir build
cd build
cmake ..


10.
make -j8
make tests
```

11. NOTE: setup.py 第一行改为
```
"#!/usr/bin/python3" （此地址可以通过which python3来确定)
```

```
sudo ./setup.py install
```
(如果在windows下手动修改，会在运行install时报错。

用file命令查看文件类型:
可以看到行分隔符是CRLF模式，这是Windows格式的换行符，会在每行行末加多一个^M，Linux不识别，具体可以查看CRLF和LF的区别。 解决方法是替换掉^M符号，重新生成一个文件：
```
cat -v setup.py | sed -e '1,$s/\^M$//g' > setup.py
```
```
12. python3 -c "import pymesh; pymesh.test()"
```

执行上面这句话可能会报错，由于使用了已弃用的 np.float 引发了多个错误。为了修复这些错误，需要将所有使用 np.float 的地方替换为 np.float64。

找到pymesh2的安装目录，用sudo 模式的vscode打开，然后查找替换，把np.float 替换为 np.float64

或者用以下命令:
```
sudo sed -i 's/np\.float/np.float64/g' /usr/local/lib/python3.8/dist-packages/pymesh2-0.3-py3.8-linux-x86_64.egg/pymesh/misc/quaternion.py
```

然后再次测试:
```
python3 -c "import pymesh; pymesh.test()"
```
