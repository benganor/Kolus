import sys 
from PyQt5 import QtWidgets, QtGui, QtCore
import matplotlib.pyplot as plt

# ... Your other imports ...

def generate_options_figure_vsr(handles, pp):
    # ... Load tag from handles (assuming access mechanism exists)...

    options_window = QtWidgets.QMainWindow()
    # ... (Window setup as before) ...

    # ... (Input widget creation as before) ... 

    # Matplotlib Figure and Axes
    fig, ax = plt.subplots()  
    stim_full = fig.canvas.draw()  

    # Add matplotlib figure to PyQt layout
    mpl_widget = QtWidgets.QWidget()
    mpl_layout = QtWidgets.QVBoxLayout(mpl_widget)
    mpl_layout.addWidget(fig.canvas)  
    layout.addWidget(mpl_widget) 

    # ... (Button setup) ... 

    # Update plot in generatestim_callback
    def generatestim_callback(duration_edit, notes_edit, handles):
        # ... Get tag from handles ...
        output_stims = kolus_gen_stim(tag) 
        stim_t = linspace(1/tag.fs, length(output_stims)/tag.fs, length(output_stims))

        ax.clear()  
        ax.plot(stim_t, output_stims)
        ax.set_xlim([0, length(output_stims)/tag.fs]) 
        fig.canvas.draw() 
        fig.canvas.flush_events()  

    # Connect generate_stim_button 
    generate_stim_button.clicked.connect(generatestim_callback)

    options_window.show() 

