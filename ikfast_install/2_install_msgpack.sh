# Install msgpack-c-cpp-6.0.0
wget https://github.com/msgpack/msgpack-c/archive/refs/tags/cpp-6.0.0.tar.gz
tar -xzf cpp-6.0.0.tar.gz
cd msgpack-c-cpp-6.0.0/
mkdir build
cd build
cmake ..
make
sudo make install
cd ../../
