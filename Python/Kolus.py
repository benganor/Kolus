from K_config import *
import sys
import pyvisa
from PyQt5 import QtWidgets, QtCore 

def kolus_gen_fig():
    app = QtWidgets.QApplication(sys.argv)
    window = QtWidgets.QMainWindow()
    window.show()  
    app.exec()

def kolus_initDAQ():
   rm = pyvisa.ResourceManager()

if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv) 
    if not sys.argv:  # No command-line argument
        path = QtWidgets.QFileDialog.getExistingDirectory()
        QtCore.QDir.setCurrent(path) 
    else:
        QtCore.QDir.setCurrent(sys.argv[1])

    rm = pyvisa.ResourceManager()
    daq_device = rm.open_resource("DAQ_resource_name") 

    # ... Initialize global variables (pp, tag, handles)...
    # ... Configure DAQ parameters ...

    setup_gui()  # If you have a GUI

    # Connect GUI signals/slots to functions, for example:
    # some_button.clicked.connect(kolus_button_record)  

    app = QtWidgets.QApplication(sys.argv)
    window = MainWindow() 
    window.show() 
    app.exec_()
    kolus_gen_fig() 
    kolus_initDAQ()

if __name__ == "__main__":
    main()