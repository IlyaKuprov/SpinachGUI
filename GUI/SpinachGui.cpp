// SpinachGUI.cpp : main project file.

#include "stdafx.h"
#include "MainForm.h"

using namespace SpinachGUI;


//---------------------------------------------------------------------------
/*! \mainpage Spinach GUI 1.0
 * \image html logo.ico
 * \section intro_sec Introduction
 *
 * Spinach GUI is the front-end of the Spinach Matlab plugin core which is 
 * fast (polynomially scaling) open-source Liouville space spin dynamics
 * 
 * simulation library developed at University of Southampton,
 * and has been developed to visualize 3D molecular spin systems. 
 *
 *  Spinach supports NMR, EPR, DNP, MAS, Optimal Control, PHIP 
 *  and other forms of Magnetic Resonance spectroscopy.
 *
 * \section Features
 *
 * - Open/Save SpinXML format
 * - Import Gauss, XYZ, CASTEP
 * - Export Spinach, EasySpin, Simpson
 * - Molecule/ Electron cloud regions
 * - Visuliazation of nuclei: Hyperfine, Chemical Shift, Bonds, Quadropolar, J-couplings 
 * - Visuliazation of electron: G-Tensor, Exchange coupling, Zero Field
 * 
 *
 * \section inst Installation 
 * You need at least MS Visual Studio 2012 for loading the project and solution files.
 *
 * Everything is setup there. %Unit testing framework(called TestSpinachGUI) is setup
 * for the debug configuration only.
 *
 * Due to some difficulties with MS visual studio 2012, 
 * during the compilation of the debug configuration, a second
 * compilation runs in order to produce a .dll file in order to used with the unit testing.
 *
 * In order to used the updated .dll file, rebuild the TestSpinachGUI nad then run the tests.
 *
 * \section start Guide for developers
 * The entry point function of SpinachGUI is the \ref main() "main" function and consequently the 
 * \ref SpinachGUI::MainForm "MainForm" class/form. This class is initiates 
 * the main application object.
 *
 * The core system is saved in the class \ref Model "Model" which is class that
 * follow the SpinXML prototype but differs for practicallity internally.
 *
 * The input/output formats are saved inside the IO Format folder and most of them derive from
 * the \ref SpinachGUI::IOSpinSystem  "IOSpinSystem" class.
 *
 * The OpenGL 3D engine is mainly in the \ref OpenGLForm::COpenGL "COpenGL" class.
 *
 * \section list Wish List
 * - Improve filter distribution bars
 * 
 *
 */
//---------------------------------------------------------------------------

/**
* Main function, entry point of the program
* @param args Array with arguments when application called from terminal line with extra args.
* If the next argument file then opens it automatically.
*/
[STAThreadAttribute]
int main(array<System::String ^> ^args)
{
	// Enabling Windows XP visual effects before any controls are created
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 

	// Create the main window and run it, without any file
	if(args->Length==0) 
	{
		MainForm ^ mainform=gcnew MainForm(gcnew String(""));
		mainform->Visible=false;
		Application::Run(mainform);
	} //or open with the file
	else Application::Run(gcnew MainForm((String^)args[0]));
	return 0;
}        

