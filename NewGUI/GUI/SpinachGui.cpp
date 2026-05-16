#include "stdafx.h"
#include "MainForm.h"

using namespace SpinachGUI;


/**
* Main function, entry point of the program
* @param args Array with arguments when application called from terminal line with extra args.
* If the next argument file then opens it automatically.
*/
[STAThreadAttribute]
int main(cli::array<System::String ^> ^args)
{
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 

	if(args->Length==0)
	{
		MainForm ^ mainform=gcnew MainForm(gcnew String(""));
		mainform->Visible=false;
		Application::Run(mainform);
	}
	else
	{
		Application::Run(gcnew MainForm((String^)args[0]));
	}
	return 0;
}        
