from K_config import *
import sys
#import pyvisa
#from PyQt5 import QtWidgets 

def kolus_gen_fig():
    app = QtWidgets.QApplication(sys.argv)
    window = QtWidgets.QMainWindow()
    window.show()  
    app.exec()

def kolus_initDAQ():
    rm = pyvisa.ResourceManager()

if __name__ == '__main__':
    if not sys.argv:  # No command-line argument
        path = QtWidgets.QFileDialog.getExistingDirectory()
        QtWidgets.QDir.setCurrent(path)
    else:
        QtWidgets.QDir.setCurrent(sys.argv[1])

    kolus_gen_fig() 
    kolus_initDAQ()