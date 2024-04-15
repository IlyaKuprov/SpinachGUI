#include "StdAfx.h"
#include "MainForm.h"


//MainForm  main rutines
System::Void SpinachGUI::MainForm::MainForm_Initialization() 
{
	MyResources = 
		(gcnew System::ComponentModel::ComponentResourceManager(MainForm::typeid));
	System::Threading::Thread::CurrentThread->CurrentCulture=gcnew System::Globalization::CultureInfo( "en-US",	false);

	SystemModel=gcnew Model();
	SystemModel->PropertyChanged+=gcnew PropertyChangedEventHandler(this,&MainForm::ModelChange);
	CurrentTitleFile=gcnew String("SpinXML1");
	this->MouseWheel += gcnew System::Windows::Forms::MouseEventHandler(this,&MainForm::OnMouseWheel);
	


	//Add elements to drop down menu for elements
	ArrayList^ Isotopes_Collection=Isotopes::getAllIsotopes();
	NodesToDeleted=gcnew ArrayList();
	this->Column4->Items->Add(((Isotope^)Isotopes_Collection[0])->Element); 
	for(int i=0;i<Isotopes_Collection->Count;i++) 
	{ 
		if(i>0 && ((Isotope^)Isotopes_Collection[i])->Element!=
			((Isotope^)Isotopes_Collection[i-1])->Element)
			this->Column4->Items->Add((String^)((Isotope^)Isotopes_Collection[i])->Element); 
	}

	dataGridView1->AutoGenerateColumns=false;
	dataGridView2->AutoGenerateColumns=false;
	//Initialize the first line of atoms table
	//this->dataGridView1->TopLeftHeaderCell->Value="Add atom";
	//this->dataGridView1->Rows[0]->HeaderCell->Value = gcnew String("+Atom");
	dataGridView1[0,0]->Value = "new";
	this->dataGridView1[2,0]->Value="";
	dataGridView1[1,0]->ReadOnly=true;
	dataGridView1[3,0]->ReadOnly=true;
	dataGridView1[4,0]->ReadOnly=true;dataGridView1[5,0]->ReadOnly=true;
	dataGridView1[6,0]->ReadOnly=true;dataGridView1[7,0]->ReadOnly=true;
	dataGridView1[8,0]->ReadOnly=true;

	MyResources2=(gcnew System::ComponentModel::ComponentResourceManager(About::typeid));
	((DataGridViewImageCell ^)dataGridView1[8,0])->ValueIsIcon=true;
	((DataGridViewImageCell ^)dataGridView1[8,0])->Value =
		(cli::safe_cast<System::Drawing::Icon^  >(MyResources2->GetObject(L"$this.Icon")));
	Column9->ValuesAreIcons=true;

	//Initialize the first line of atoms table
	dataGridView2[6,0]->Value="Edit";
	dataGridView2[0,0]->Value = "new";
	dataGridView2[1,0]->ReadOnly=true;
	dataGridView2[3,0]->ReadOnly=true;
	dataGridView2[4,0]->ReadOnly=true;
	dataGridView2[5,0]->ReadOnly=true;
	dataGridView2[6,0]->ReadOnly=true;
	dataGridView2[7,0]->ReadOnly=true;
	((DataGridViewImageCell ^)dataGridView2[7,0])->ValueIsIcon=true;
	((DataGridViewImageCell ^)dataGridView2[7,0])->Value =
		(cli::safe_cast<System::Drawing::Icon^  >(MyResources2->GetObject(L"$this.Icon")));
	Column12->ValuesAreIcons=true;



	int gap=2; //OpenGL panel margin
	//OpenGL = gcnew COpenGL(this,
	//	                   System::Drawing::Point(tableLayoutPanel13->Width+gap/2,this->tabControl1->Height+gap/2),
	//	                   this->ClientSize.Width-tableLayoutPanel13->Width-tableLayoutPanel4->Width-gap,
	//	                   this->ClientSize.Height-this->tabControl1->Height-gap);
	OpenGL = gcnew COpenGL(this,
		                   System::Drawing::Point(0,0),
		                   splitContainer2->Panel1->Width,
		                   splitContainer2->Panel1->Height);
	
	//OpenGL->SuspendLayout();
	//OpenGL->Controls->Add(splitContainer2->Panel1);
	//OpenGL->ResumeLayout(false);

	splitContainer2->Panel1->SuspendLayout();
	splitContainer2->Panel1->Controls->Add(OpenGL);
	splitContainer2->Panel1->ResumeLayout(false);
  Update_Interactions_Color();




	//check boxes
	checkBoxAxes->Checked=OpenGL->AxesFlag;
	GTcheckBox->Checked=OpenGL->GTFlag;	
	CHITcheckBox->Checked=OpenGL->CHITFlag;
	CScheckBox->Checked=OpenGL->CSFlag;
	HFCcheckBox->Checked=OpenGL->HCFlag;
	BondcheckBox->Checked=OpenGL->CBFlag;
	JCcheckBox->Checked=OpenGL->JCFlag;
//	DCcheckBox->Checked=OpenGL->DCFlag;
	QCcheckBox->Checked=OpenGL->QCFlag;
	ECcheckBox->Checked=OpenGL->ECFlag;
	ZFcheckBox->Checked=OpenGL->ZFFlag;

	UseTrackBarEventHandler=true;
	//EventHandlers for Trackbars-Placed manually because the autogeneration forget them from times to times.
	this->HFCtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::HFCtrackBar_Scroll);
	this->CStrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::CStrackBar_Scroll);
	this->GTtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::GTtrackBar_Scroll);		
	this->CHITtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::CHITtrackBar_Scroll);
	this->BondtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::BondtrackBar_Scroll);
	this->JCtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::JCtrackBar_Scroll);
//	this->DCtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::DCtrackBar_Scroll);
	this->QCtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::QCtrackBar_Scroll);
	this->ECtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::ECtrackBar_Scroll);
	this->ZFtrackBar->ValueChanged += gcnew gTrackBar::gTrackBar::ValueChangedEventHandler(this, &MainForm::ZFtrackBar_Scroll);

	//NativeWindow^ xlMain = gcnew NativeWindow();
	//xlMain->AssignHandle(IntPtr((HWND)this->Handle.ToPointer()));
	//String^ name = AppDomain::CurrentDomain->FriendlyName;
	//array <Diagnostics::Process^>^ pro = 
	//	Diagnostics::Process::GetProcessesByName(name->Substring(0, name->LastIndexOf('.')));

	//button2->OnMouseEnter(gcnew EventArgs());
	

	BalloonToolTip1=gcnew BalloonToolTip("Add atom by selecting element");
	BalloonToolTip2=gcnew BalloonToolTip("Add interaction by selecting Atom ID");
	
	this->AddOwnedForm( BalloonToolTip1 );
	this->AddOwnedForm( BalloonToolTip2 );

	labelflag=true;
	easyspin = gcnew EasySpin();	
	spinach = gcnew Spinach();	
	simpson=gcnew Simpson();
	spinEvolution=gcnew SpinEvolution();
	
      
}

System::Void SpinachGUI::MainForm::MainForm_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) 
{
	OpenGL->UpdateDisplay(UpdateType::ALL);
	OpenGL->SwapOpenGLBuffers();
	dataGridView_Helpers();
}

System::Void SpinachGUI::MainForm::MainForm_Resize(System::Object^  sender, System::EventArgs^  e) 
{

	int gap=2; //OpenGL panel margin
	dataGridView_Helpers();


}

System::Void SpinachGUI::MainForm::MainForm_Shown(System::Object^  sender, System::EventArgs^  e) {
			  OpenGL->Render();
		 }
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Open and Save File
System::Void SpinachGUI::MainForm::Newbutton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->Reset();
	OpenGL->Home();
	dataGridView1->Rows->Clear(); 
	SystemModel->AtomCollection->Clear();
	dataGridView2->Rows->Clear();	
	SystemModel->InteractionCollection->Clear();
	dataGridView2->Rows->Clear();	
	SystemModel->RefFrameCollection->Clear();
	CurrentTitleFile="SpinXML1";
	CurrentSavedFile=nullptr;
	this->Text=CurrentTitleFile+"- Spinach GUI "+SpinachGUIver;
	Savebutton->Enabled=false;
	ModelFileName->Text="Imported File: (None)";
	Reset();
	OpenGL->UpdateDisplay(UpdateType::ALL);



}

System::Void SpinachGUI::MainForm::OpenFileButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenFilesDialog->Filter="SpinXML File|*.sxml";
	if (OpenFilesDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		OpenGL->Reset();
		OpenGL->Home();
		dataGridView1->Rows->Clear(); 
		dataGridView2->Rows->Clear();	
		SystemModel->AtomCollection->Clear();
		SystemModel->InteractionCollection->Clear();
		SystemModel->RefFrameCollection->Clear();
		Reset();
		OpenGL->UpdateDisplay(UpdateType::ALL);
		GenprogressBar->Visible=true;

		if(OpenFilesDialog->FilterIndex==1) 	OpenSpinXML(OpenFilesDialog->FileName);
	};


}

System::Void SpinachGUI::MainForm::OpenSpinXML(String ^ FileName) 
{
			SpinXML^ OpenedFile= gcnew SpinXML(FileName, IOSpinSystem::FilterType::IMPORT, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);	   
}

System::Void SpinachGUI::MainForm::Importbutton_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenFilesDialog->Filter="Gaussian3 File|*.log;*.out|"+
		                     "mol File|*.mol|"+
							 "xyz File|*.xyz|"+
							 "CASTEP File|*.magres|"+
							 "Orca File|*.log;*.out|"+
							 "ADF File|*.out|"+
	                         "GAMESS File|*.out|"+
							 "COSMOS File|*.coo";

	//|All Files|*.*
	if (OpenFilesDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		OpenGL->Reset();
		OpenGL->Home();
		dataGridView1->Rows->Clear(); 
		dataGridView2->Rows->Clear();	
		SystemModel->AtomCollection->Clear();
		SystemModel->InteractionCollection->Clear();
		SystemModel->RefFrameCollection->Clear();
		Reset();
		OpenGL->UpdateDisplay(UpdateType::ALL);
		GenprogressBar->Visible=true;

		if(OpenFilesDialog->FilterIndex==1) //Gaussian
		{

			Gauss^ OpenedFile= gcnew Gauss(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);

		}
		else if(OpenFilesDialog->FilterIndex==4) //Castep
		{
			Castep^ OpenedFile= gcnew Castep(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);
		}
		else if(OpenFilesDialog->FilterIndex==3) //xyz
		{
			
			XYZ^ OpenedFile= gcnew XYZ(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);

		}
		else if(OpenFilesDialog->FilterIndex==2) //mol
		{
			MOL^ OpenedFile= gcnew MOL(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);
		}
		else if(OpenFilesDialog->FilterIndex==5) //Orca
		{
			Orca^ OpenedFile= gcnew Orca(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);
		}
		else if(OpenFilesDialog->FilterIndex==6) //ADF
		{
			ADF^ OpenedFile= gcnew ADF(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);	
			
		}
		else if(OpenFilesDialog->FilterIndex==7) //GAMESS
		{
			GAMESS^ OpenedFile= gcnew GAMESS(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);	
		}
		else if(OpenFilesDialog->FilterIndex==8) //COSMOS
		{
			COSMOS^ OpenedFile= gcnew COSMOS(OpenFilesDialog->FileName, gcnew Model());
			this->Enabled=false;
			ImportbackgroundWorker->RunWorkerAsync(OpenedFile);
		}

	
		
	};


}

System::Void SpinachGUI::MainForm::LoadModel() 
{

	int line;
    for each(int i in SystemModel->AtomCollection->Keys)
		{
		 //Number of line
		 line=dataGridView1->Rows->Count-1;
		 //Add a new line
	     dataGridView1->Rows->Add();
		 //Set line readable
		 dataGridView1[1,line]->ReadOnly=false;
		 dataGridView1[3,line]->ReadOnly=false;
	 	 dataGridView1[5,line]->ReadOnly=false;
		 dataGridView1[6,line]->ReadOnly=false;
		 dataGridView1[7,line]->ReadOnly=false;
		 //Set ID, Label, and element
		 dataGridView1[0,line]->Value=((Atom^)SystemModel->AtomCollection[i])->getID();
		 dataGridView1[1,line]->Value=((Atom^)SystemModel->AtomCollection[i])->Label;
		 dataGridView1[2,line]->Value=((Atom^)SystemModel->AtomCollection[i])->isotope->Element;
	     
		 //Create the dropdown menu for the mass of the elements
		 DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
		 combobox->Items->AddRange(Isotopes::getAllIsotopeMasses(Convert::ToString(dataGridView1[2,line]->Value)));
		 dataGridView1[3,line]=combobox;
		 //Set Mass
		 dataGridView1[3,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->isotope->Mass);


		 //Import the color of the isotope from each atom
		 Color^ acolor=gcnew Color;
		 dataGridView1[4,line]->Style->BackColor=acolor->FromArgb(255,
				              (int)(((Atom^)SystemModel->AtomCollection[i])->isotope->Red*255),
				              (int)(((Atom^)SystemModel->AtomCollection[i])->isotope->Green*255),
				              (int)(((Atom^)SystemModel->AtomCollection[i])->isotope->Blue*255));
		 dataGridView1[4,line]->Style->SelectionBackColor=dataGridView1[4,i]->Style->BackColor;

		 //Import the coordinates of the atom
		 dataGridView1[5,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->X);
		 dataGridView1[6,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->Y);
		 dataGridView1[7,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->Z);
		}

	DataGridView_Interactions_Update();

	OpenGL->ZoomtoFillScreen();
	 OpenGL->UpdateDisplay(UpdateType::ALL);

  
		
}

System::Void SpinachGUI::MainForm::UpdateCoordinates() 
{

		int line;
    for each(int i in SystemModel->AtomCollection->Keys)
		{
		 //Number of line
		 line=i-1;

		 //Import the coordinates of the atom
		 dataGridView1[5,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->X);
		 dataGridView1[6,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->Y);
		 dataGridView1[7,line]->Value=Convert::ToString(((Atom^)SystemModel->AtomCollection[i])->Z);
		}

	DataGridView_Interactions_Update();

	OpenGL->ZoomtoFillScreen();
	 OpenGL->UpdateDisplay(UpdateType::ALL);

}

System::Void SpinachGUI::MainForm::SaveAsButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	SaveFilesDialog->Filter="SpinXML File|*.sxml";
	SaveFilesDialog->FileName=Path::GetFileNameWithoutExtension(CurrentTitleFile)+".sxml";
	if (SaveFilesDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		SpinXML^ OpenedFile= gcnew SpinXML(SaveFilesDialog->FileName,IOSpinSystem::FilterType::EXPORT, SystemModel);

		CurrentSavedFile=SaveFilesDialog->FileName;
		CurrentTitleFile=Path::GetFileName(CurrentSavedFile);
		ModelFileName->Text="Imported File: (None)";
		this->Text=CurrentTitleFile+"- Spinach GUI "+SpinachGUIver;
		OpenedFile->WriteFile(SystemModel);
		Savebutton->Enabled=false;
	    if(Text->Contains("*")) this->Text=this->Text->Replace(" *", "");

	};


}

System::Void SpinachGUI::MainForm::Savebutton_Click(System::Object^  sender, System::EventArgs^  e)
{
	if(CurrentSavedFile!=nullptr && CurrentSavedFile!="")
	{
		SpinXML^ OpenedFile= gcnew SpinXML(CurrentSavedFile,IOSpinSystem::FilterType::EXPORT, SystemModel);
		OpenedFile->WriteFile(SystemModel);
		Savebutton->Enabled=false;
	    if(Text->Contains("*")) this->Text=this->Text->Replace(" *", "");
	}
	else
	{
		SaveFilesDialog->Filter="SpinXML File|*.sxml";
		SaveFilesDialog->FileName=Path::GetFileNameWithoutExtension(CurrentTitleFile)+".sxml";
		if (SaveFilesDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
		{
			SpinXML^ OpenedFile= gcnew SpinXML(SaveFilesDialog->FileName,IOSpinSystem::FilterType::EXPORT, SystemModel);
			CurrentSavedFile=SaveFilesDialog->FileName;
			CurrentTitleFile=Path::GetFileName(CurrentSavedFile);
			ModelFileName->Text="Imported File: (None)";
			this->Text=CurrentTitleFile+"- Spinach GUI "+SpinachGUIver;
			OpenedFile->WriteFile(SystemModel);
			Savebutton->Enabled=false;
	        if(Text->Contains("*")) this->Text=this->Text->Replace(" *", "");
		};
	};

}

System::Void SpinachGUI::MainForm::AboutButton_Click(System::Object^  sender, System::EventArgs^  e)
{
	About^ aboutdialog = gcnew About();	
	aboutdialog->ShowDialog();
}

System::Void SpinachGUI::MainForm::Printbutton_Click(System::Object^  sender, System::EventArgs^  e) 
{

	if ( printDialog1->ShowDialog() == ::DialogResult::OK )
	{
		DocumenttoPrint->Print();
	}
}

System::Void SpinachGUI::MainForm::DocumenttoPrint_PrintPage(System::Object^  sender, System::Drawing::Printing::PrintPageEventArgs^  e) 
{
	e->Graphics->DrawImage(OpenGL->Save_BMP(), 0, 0);
}

System::Void SpinachGUI::MainForm::checkBoxAtomID_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->AtomIDFlag=checkBoxAtomID->Checked;
	 //OpenGL->Render();
	OpenGL->UpdateDisplay(UpdateType::ATOMS);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Export

System::Void SpinachGUI::MainForm::ExportBitmap_Click(System::Object^  sender, System::EventArgs^  e) 
{
	SaveFilesDialog->Filter="Bitmap File|*.bmp";
	SaveFilesDialog->FileName=CurrentTitleFile+".bmp";
	if (SaveFilesDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		OpenGL->Save_BMP()->Save(SaveFilesDialog->FileName, System::Drawing::Imaging::ImageFormat::Bmp);
	}
}

System::Void SpinachGUI::MainForm::ExportEasyspin_Click(System::Object^  sender, System::EventArgs^  e) 
{


	if(SystemModel->AtomCollection->get_electron_number())
	{
		easyspin->EasySpin_Initialization(SystemModel, CurrentTitleFile);
		easyspin->ShowDialog();
	}
	else
		MessageBox::Show("No electrons in  the system. Easyspin requires at least one"+ 
		" electron in the system. Create one in order to export to Easyspin format.", "Error", 
		MessageBoxButtons::OK, MessageBoxIcon::Error) ;
}

System::Void SpinachGUI::MainForm::ExportSpinEvolution_Click(System::Object^  sender, System::EventArgs^  e) 
{

	if(!SystemModel->AtomCollection->get_electron_number())
	{
		if(SystemModel->AtomCollection->Count>0)
		{
			spinEvolution->Initialize_SpinEvolution(SystemModel, CurrentTitleFile);
			spinEvolution->ShowDialog();
		}
		else
			MessageBox::Show("No atoms in system. Add one in order to export to Simpson format.", "Error", 
			MessageBoxButtons::OK, MessageBoxIcon::Error) ;

	}
	else
		MessageBox::Show("Electrons are not supported by SpinEvolution. Delete all electrons"+
		" from the spin system to enable export into SpinEvolution format.", "Error", 
		MessageBoxButtons::OK, MessageBoxIcon::Error) ;
}

System::Void SpinachGUI::MainForm::ExportSpinach_Click(System::Object^  sender, System::EventArgs^  e)
{
	spinach->Spinach_Initialization(SystemModel, CurrentTitleFile);
	spinach->ShowDialog();
}

System::Void SpinachGUI::MainForm::ExportSimpson_Click(System::Object^  sender, System::EventArgs^  e)
{
	if(!SystemModel->AtomCollection->get_electron_number())
	{
		if(SystemModel->AtomCollection->Count>0)
		{

			simpson->Initialize_Simpson(SystemModel, CurrentTitleFile);
			simpson->ShowDialog();
		}
		else
			MessageBox::Show("No atoms in system. Add one in order to export to Simpson format.", "Error", 
			MessageBoxButtons::OK, MessageBoxIcon::Error) ;
	}
	else
		MessageBox::Show("Electrons are not supported by Simpson. Delete all electrons"+
		" from the spin system to enable export into Simpson format.", "Error", 
		MessageBoxButtons::OK, MessageBoxIcon::Error) ;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Edit Datagridview for Atoms
System::Void SpinachGUI::MainForm::dataGridView1_CellEndEdit(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	int AtomID;
	if (e->ColumnIndex==2 &&
		(String^)dataGridView1[e->ColumnIndex,e->RowIndex]->Value!="" ) //Change Element
	{
		
		if (insertAtom) //insert Atom
		{
			//Creat an atom and add in the collection in order to take ID
			Atom^ nAtom=gcnew Atom();
			SystemModel->AtomCollection->Add(nAtom);
			//Atom ID
			dataGridView1[0,e->RowIndex]->Value=nAtom->getID();
			AtomID=nAtom->getID();

			//Unlock Atom table cells
			dataGridView1[1,e->RowIndex]->ReadOnly=false;
			dataGridView1[3,e->RowIndex]->ReadOnly=false;
			dataGridView1[5,e->RowIndex]->ReadOnly=false;
			dataGridView1[6,e->RowIndex]->ReadOnly=false;
			dataGridView1[7,e->RowIndex]->ReadOnly=false;

			//Atom Coordinates
			dataGridView1[5,e->RowIndex]->Value=
				Convert::ToString(((Atom^)SystemModel->AtomCollection[AtomID])->X);
			dataGridView1[6,e->RowIndex]->Value=
				Convert::ToString(((Atom^)SystemModel->AtomCollection[AtomID])->Y);
			dataGridView1[7,e->RowIndex]->Value=
				Convert::ToString(((Atom^)SystemModel->AtomCollection[AtomID])->Z);
		}
		else AtomID=Convert::ToInt32(dataGridView1[0,e->RowIndex]->Value);

		//Select isotope
		((Atom^)SystemModel->AtomCollection[AtomID])->isotope=
			Isotopes::FindIsotope((String^)dataGridView1[2,datagridview1_row]->Value,0, 0);
		
		//Create Masses of isotope dropdown menu
        this->Column5->Items->Clear();
		DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();

		//Set the values for the masses dropdown menu
		combobox->Items->AddRange(
			Isotopes::getAllIsotopeMasses((String^)dataGridView1[2,datagridview1_row]->Value));
		dataGridView1[3,datagridview1_row]=combobox;

		//Set the value for the mass cell
		dataGridView1[3,datagridview1_row]->Value=combobox->Items[0];


		//Set Atom-Isotope Color to cell
		Color^ acolor=gcnew Color;
		dataGridView1[4,datagridview1_row]->Style->BackColor=acolor->FromArgb(255,
			(int)(((Atom^)SystemModel->AtomCollection[AtomID])->isotope->Red*255),
			(int)(((Atom^)SystemModel->AtomCollection[AtomID])->isotope->Green*255),
			(int)(((Atom^)SystemModel->AtomCollection[AtomID])->isotope->Blue*255));
		dataGridView1[4,datagridview1_row]->Style->SelectionBackColor=
			dataGridView1[4,datagridview1_row]->Style->BackColor;
		
	}
	else if (e->ColumnIndex==3) //Change Mass
	{
	  AtomID=Convert::ToInt32(dataGridView1[0,e->RowIndex]->Value);
      ((Atom^)SystemModel->AtomCollection[AtomID])->isotope=
			Isotopes::FindIsotope((String^)dataGridView1[2,datagridview1_row]->Value,0,
			                       Convert::ToInt32(dataGridView1[3,datagridview1_row]->Value));
	}
	else if (e->ColumnIndex==1) //Change Label
	{
	  AtomID=Convert::ToInt32(dataGridView1[0,e->RowIndex]->Value);
      ((Atom^)SystemModel->AtomCollection[AtomID])->Label=
										((String^)dataGridView1[1,e->RowIndex]->Value);
	}
	else if(e->ColumnIndex>4)  //Change Coordinates
	{
		double result;
		AtomID=Convert::ToInt32(dataGridView1[0,e->RowIndex]->Value);

		//Can change coordinates only for non electrons
		if(((Atom^)SystemModel->AtomCollection[AtomID])->isotope->Element!="e")
		{
			if(Double::TryParse((String^)dataGridView1[e->ColumnIndex,e->RowIndex]->Value, result))
			{
				switch(e->ColumnIndex)
				{
					break;
				case 5:
					((Atom^)SystemModel->AtomCollection[AtomID])->X=
						Convert::ToDouble((String^)dataGridView1[5,e->RowIndex]->Value);
					break;
				case 6:
					((Atom^)SystemModel->AtomCollection[AtomID])->Y=
						Convert::ToDouble((String^)dataGridView1[6,e->RowIndex]->Value);					
					break;
				case 7:
					((Atom^)SystemModel->AtomCollection[AtomID])->Z=
						Convert::ToDouble((String^)dataGridView1[7,e->RowIndex]->Value);					
					break;
				};
			} 
			else
			{
				MessageBox::Show("Wrong Number Format for Coordinates", "Error", 
					MessageBoxButtons::OK, MessageBoxIcon::Error) ;
				SetColumnIndex^ method= gcnew SetColumnIndex(this, &MainForm::DelegateMethod);
				dataGridView1->BeginInvoke(method,e->ColumnIndex,e->RowIndex);
			}
		}

	}

	//Change the color of the cell back to original color
	dataGridView1[e->ColumnIndex,e->RowIndex]->Style->BackColor=System::Drawing::SystemColors::Window;

	//Update the datagridview2 with the updated atom properties
	dataGridView2->Rows->Clear();
	DataGridView_Interactions_Update();
   
	//Update the OpenGL screen
	OpenGL->ZoomtoFillScreen();
	 OpenGL->UpdateDisplay(UpdateType::ALL);
}

System::Void SpinachGUI::MainForm::DelegateMethod(int columnIndex, int rowIndex)
{
	dataGridView1->CurrentCell = dataGridView1[columnIndex,rowIndex];
	dataGridView1->BeginEdit(true);
}
System::Void SpinachGUI::MainForm::Delegate2Method(int columnIndex, int rowIndex)
{
	dataGridView1->CurrentCell = dataGridView1[columnIndex,rowIndex];
	dataGridView1->EndEdit();
}

System::Void SpinachGUI::MainForm::dataGridView1_CellBeginEdit(System::Object^  sender, System::Windows::Forms::DataGridViewCellCancelEventArgs^  e) 
{ 
 //Set the current row and column of the cell
 datagridview1_column=e->ColumnIndex;
 datagridview1_row=e->RowIndex;

 //Highlight the current cell
 dataGridView1[e->ColumnIndex,e->RowIndex]->Style->BackColor=System::Drawing::SystemColors::Highlight;
 
 if (e->ColumnIndex==2) //Choose of isotope
 {
	 //If isotope column empty, it means a new atom is inserted
	 if ((String^)dataGridView1[e->ColumnIndex,e->RowIndex]->Value=="") insertAtom=true;
	 else insertAtom=false;
 };

 //Set the current cell for coordinates
 if (e->ColumnIndex>4 )  DataGridViewCell^ currentCell=dataGridView1[e->ColumnIndex,e->RowIndex];
}
//------------------------------
System::Void SpinachGUI::MainForm::dataGridView1_EditingControlShowing(System::Object^  sender, System::Windows::Forms::DataGridViewEditingControlShowingEventArgs^  e) 
{
	//For coordinates columns set keypress event handler
	if (datagridview1_column>4)
	{
		TextBox^ txtbox = (TextBox^)(e->Control);
		if (txtbox != nullptr) txtbox->KeyPress += 
			gcnew KeyPressEventHandler(this,&MainForm::txtbox_KeyPress);
	}
	//For dropmenu columns set selectedindexchanged handler
	else if (datagridview1_column==2 || datagridview1_column==3 )
	{
		ComboBox^ cmbbox = (ComboBox^)(e->Control);
		if (cmbbox != nullptr) cmbbox->SelectedIndexChanged -= 
			gcnew System::EventHandler( this, &MainForm::cmbbox_SelectedIndexChanged );
		if (cmbbox != nullptr) cmbbox->SelectedIndexChanged += 
			gcnew System::EventHandler( this, &MainForm::cmbbox_SelectedIndexChanged );
	};
}

System::Void SpinachGUI::MainForm::txtbox_KeyPress(System::Object^  sender, System::Windows::Forms::KeyPressEventArgs^  e) 
{
 // For coordinates columns, determine whether the keystroke is a number.
 if (datagridview1_column>4 && !Char::IsNumber(e->KeyChar) && e->KeyChar != '\b' &&
	 e->KeyChar != '.' && e->KeyChar != '-') e->Handled = true;
 }

System::Void SpinachGUI::MainForm::cmbbox_SelectedIndexChanged(System::Object^  sender, EventArgs^ e) 
{
	/*
	ComboBox^ cmbbox = (ComboBox^)sender;
	dataGridView1[datagridview1_column,datagridview1_row]->Value=cmbbox->SelectedItem->ToString();
	cmbbox->SelectedItem=dataGridView1[datagridview1_column,datagridview1_row]->Value;

	//Create Combo box for mass number of isotopes after choosing element
	if(datagridview1_column==2 && cmbbox->SelectedItem!="")
	{
		this->Column5->Items->Clear();

		DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
		combobox->Items->AddRange(Isotopes::getAllIsotopeMasses(cmbbox->SelectedItem->ToString()));
		dataGridView1[3,datagridview1_row]=combobox;

		dataGridView1[3,datagridview1_row]->Value=(String ^)combobox->Value;
		dataGridView1[3,datagridview1_row]->ReadOnly=false;		
		dataGridView1[3,datagridview1_row]->Value=combobox->Items[0];

	}

	OpenGL->Render();
	*/
}

System::Void SpinachGUI::MainForm::dataGridView1_RowsAdded(System::Object^  sender, System::Windows::Forms::DataGridViewRowsAddedEventArgs^  e)
{
	//Isotope Column empty, ready to choose  and ID colunm set "new"
	dataGridView1[2,e->RowIndex]->Value="";
	dataGridView1[0,e->RowIndex]->Value = "new";

	//Everything readonly, except isotope column 
	dataGridView1[2,e->RowIndex]->ReadOnly=false;
	dataGridView1[1,e->RowIndex]->ReadOnly=true;
	dataGridView1[3,e->RowIndex]->ReadOnly=true;
	dataGridView1[4,e->RowIndex]->ReadOnly=true;
	dataGridView1[5,e->RowIndex]->ReadOnly=true;
	dataGridView1[6,e->RowIndex]->ReadOnly=true;
	dataGridView1[7,e->RowIndex]->ReadOnly=true;

	//Set the current cell, the one just added
	dataGridView1->CurrentCell = dataGridView1[datagridview1_column,e->RowIndex];

	//Set the tooltip text for new lines
	if(e->RowIndex>0) dataGridView1->Rows[e->RowIndex-1]->HeaderCell->ToolTipText  = "";
	dataGridView1->Rows[e->RowIndex]->HeaderCell->ToolTipText  = "Add New Atom";

	//Set the last cell of the row the bin icon
	((DataGridViewImageCell ^)dataGridView1[8,e->RowIndex])->ValueIsIcon=true;
	((DataGridViewImageCell ^)dataGridView1[8,e->RowIndex])->Value =
		(cli::safe_cast<System::Drawing::Icon^  >(MyResources2->GetObject(L"$this.Icon")));

}

//For editing coordinates, label and color
System::Void SpinachGUI::MainForm::dataGridView1_CellClick(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	//Edit coordinates and label
	if ((e->ColumnIndex>4 || e->ColumnIndex==1 ) && 
		!dataGridView1[e->ColumnIndex,e->RowIndex]->ReadOnly )		 dataGridView1->BeginEdit(true);

	//Click for changing the color
	if (e->ColumnIndex==4 && 
		!dataGridView1[3,e->RowIndex]->ReadOnly &&
		GenColorDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		dataGridView1[4,e->RowIndex]->Style->BackColor=GenColorDialog->Color;
		dataGridView1[4,e->RowIndex]->Style->SelectionBackColor=GenColorDialog->Color;
	};

	//When click the bin, delete the atom
	if (e->ColumnIndex==8 && !dataGridView1[3,e->RowIndex]->ReadOnly )
	{
		dataGridView1->Rows[e->RowIndex]->Selected=true;
		dataGridView1->Rows->RemoveAt(e->RowIndex);
	};

	// Do not select the "new" row
	if(e->ColumnIndex==-1 && e->RowIndex==dataGridView1->Rows->Count-1) 
		dataGridView1->Rows[e->RowIndex]->Selected=false;

}

//When selection of an Atom change the selection in Interaction Table change
System::Void SpinachGUI::MainForm::dataGridView1_SelectionChanged(System::Object^  sender, System::EventArgs^  e) 
{
	//Clear Selected rown in datagridview2
	dataGridView2->ClearSelection();

	//Set the Selected atom ID, if "new" set it to -1(nothing) else the value in the first cell
	if(dataGridView1->SelectedRows->Count!=0) 
		SelectedAtomID=(dataGridView1->SelectedRows[dataGridView1->SelectedRows->Count-1]->Cells[0]->Value=="new"?
		-1: Convert::ToInt32((dataGridView1->SelectedRows[dataGridView1->SelectedRows->Count-1]->Cells[0]->Value)));
	
	//Check its line of datagridview2 to see if atom in column 2 and 4 are in the selected list of datagriview1
	for(int i=0;i<dataGridView2->RowCount;i++)
		for(int j=0;j<dataGridView1->SelectedRows->Count;j++)
			if(Convert::ToString(dataGridView2[2,i]->Value)==
				Convert::ToString(dataGridView1->SelectedRows[j]->Cells[0]->Value) ||
				Convert::ToString(dataGridView2[4,i]->Value)==
				Convert::ToString(dataGridView1->SelectedRows[j]->Cells[0]->Value))  
			{
				dataGridView2->Rows[i]->Selected=true;
			};


}

System::Void SpinachGUI::MainForm::dataGridView1_RowsRemoved(System::Object^  sender, 
															 System::Windows::Forms::DataGridViewRowsRemovedEventArgs^  e) 
{
 if(SystemModel->AtomCollection->Count>0 && e->RowCount<=dataGridView1->Rows->Count)
	{
	//Remove atom from AtomCollection
	SystemModel->AtomCollection->RemoveAt(SelectedAtomID);

	//Renumber atoms in datagridview1
	int jj=0;
	for each(int i in SystemModel->AtomCollection->Keys) dataGridView1[0,jj++]->Value=i;
	
	//Refresh the whole datagridview1 and Rerender
	if(dataGridView1->SelectedRows->Count==0)
		{
			dataGridView2->Rows->Clear();
		DataGridView_Interactions_Update(); 
			//OpenGL->UpdateDisplay(UpdateType::ALL);
		};

	};
}

//When mouse is above a cell, then is getting selected immidiatelly in order to avoid many clicks
System::Void SpinachGUI::MainForm::dataGridView1_CellEnter(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) {

	if(e->ColumnIndex>1 && e->ColumnIndex<4 && e->RowIndex>=0 
		&& !dataGridView1->IsCurrentCellInEditMode && dataGridView1->SelectedRows->Count<1 )
	{
		dataGridView1->CurrentCell = dataGridView1[e->ColumnIndex,e->RowIndex];
	};
}

//When we choose something from dropdown menu immidiately finish edit
System::Void SpinachGUI::MainForm::dataGridView1_CurrentCellDirtyStateChanged(System::Object^  sender, System::EventArgs^  e) {
	if(datagridview1_column==2 || datagridview1_column==3) 
		dataGridView1->EndEdit(DataGridViewDataErrorContexts::Commit);
}

System::Void SpinachGUI::MainForm::dataGridView1_MouseEnter(System::Object^  sender, System::EventArgs^  e)
{
	dataGridView1->Focus();
}

System::Void SpinachGUI::MainForm::dataGridView1_CellLeave(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	if(datagridview1_column==2 || datagridview1_column==3) 
		txtbox_KeyPress(gcnew DataGridViewTextBoxColumn(),gcnew KeyPressEventArgs((char)13)) ;
}

System::Void SpinachGUI::MainForm::dataGridView1_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) 
{
	dataGridView_Helpers();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Edit Datagridview for Interaction
System::Void SpinachGUI::MainForm::dataGridView2_CellClick(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	//Click of orientation button
	if (e->ColumnIndex==6 && e->RowIndex>-1 && !dataGridView2[e->ColumnIndex,e->RowIndex]->ReadOnly)
	{			
		int k=Convert::ToInt32(dataGridView2[0,e->RowIndex]->Value);
		//OrientationDialog^ orientationdialog= gcnew OrientationDialog();
		Check ^ method=gcnew Check(this,&SpinachGUI::MainForm::CheckExistentInteractions);
		orientationdialog->Initialization(((Tensor^)SystemModel->InteractionCollection[k]), OpenGL
			, method);
			//= gcnew OrientationDialog(((Tensor^)SystemModel->InteractionCollection[k]), OpenGL);
		orientationdialog->ShowDialog();

	};

	//Delete button deletes this row
	if (e->ColumnIndex==7 && !dataGridView2[4,e->RowIndex]->ReadOnly )
	{
		dataGridView2->Rows[e->RowIndex]->Selected=true;
		dataGridView2->Rows->RemoveAt(e->RowIndex);
	}
	// do not select the new row
	if(e->ColumnIndex==-1 && e->RowIndex==dataGridView1->Rows->Count-1) 
		dataGridView2->Rows[e->RowIndex]->Selected=false;
}

System::Void SpinachGUI::MainForm::dataGridView2_RowsRemoved(System::Object^  sender, System::Windows::Forms::DataGridViewRowsRemovedEventArgs^  e) 
{

	if(SystemModel->InteractionCollection->Count>0 && 
	   e->RowCount<=dataGridView2->Rows->Count
		//&& e->RowIndex>0 //check that
		//e->RowCount<2 //check that
		)
	{
		//Remove of interaction
		SystemModel->InteractionCollection->RemoveAt(SelectedInterID);

		//Renumbering of IDs
		for(int i=SelectedInterID;i<SystemModel->InteractionCollection->Count+1;i++)
		dataGridView2[0,i-1]->Value=((Interaction^)SystemModel->InteractionCollection[i])->getID();
	};

	if(dataGridView2->SelectedRows->Count==0)
	{
	if(SystemModel->InteractionCollection->Count>0) CheckExistentInteractions(true);

	 OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	 OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
	}

}

System::Void SpinachGUI::MainForm::dataGridView2_CellBeginEdit(System::Object^  sender, System::Windows::Forms::DataGridViewCellCancelEventArgs^  e) 
{
	datagridview2_column=e->ColumnIndex;
	datagridview2_row=e->RowIndex;

	if (e->ColumnIndex==2) 
	{
		if ((String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value=="") insertInter=true;
		else insertInter=false;
	};


}

System::Void SpinachGUI::MainForm::dataGridView2_CellEnter(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	if((e->ColumnIndex==2 || e->ColumnIndex==3 || e->ColumnIndex==4 || e->ColumnIndex==5) &&
		e->RowIndex>=0 && !dataGridView2->IsCurrentCellInEditMode &&
	    dataGridView2->SelectedRows->Count<1 )
	{
		dataGridView2->CurrentCell = dataGridView2[e->ColumnIndex,e->RowIndex];
	};



}

System::Void SpinachGUI::MainForm::dataGridView2_CurrentCellDirtyStateChanged(System::Object^  sender, System::EventArgs^  e)
		 {
	if(datagridview2_column==2 || datagridview2_column==3 || datagridview2_column==4 || datagridview2_column==5) 
		dataGridView2->EndEdit(DataGridViewDataErrorContexts::Commit);
}

System::Void SpinachGUI::MainForm::dataGridView2_RowsAdded(System::Object^  sender, System::Windows::Forms::DataGridViewRowsAddedEventArgs^  e) 
{
	//Adding the items in the Atom menu
	DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
	for each(int j in SystemModel->AtomCollection->Keys)
	{ 
		combobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->getID()));
	}
	dataGridView2[2,e->RowIndex]=combobox;

	//Atom Column empty, ready to choose  and ID colunm set "new" and edit column
	dataGridView2[2,e->RowIndex]->Value="";
	dataGridView2[0,e->RowIndex]->Value="new";
	dataGridView2[6,e->RowIndex]->Value="Edit";

	//Everything readonly, except atom 1 column
	dataGridView2[1,e->RowIndex]->ReadOnly=true;
	dataGridView2[2,e->RowIndex]->ReadOnly=false;
	dataGridView2[3,e->RowIndex]->ReadOnly=true;
	dataGridView2[4,e->RowIndex]->ReadOnly=true;
	dataGridView2[5,e->RowIndex]->ReadOnly=true;
	dataGridView2[6,e->RowIndex]->ReadOnly=true;
	dataGridView2[7,e->RowIndex]->ReadOnly=true;

	//Set the current cell, the one just added
	dataGridView2->CurrentCell = dataGridView2[datagridview2_column,e->RowIndex];

		
	//Set the tooltip text for new lines
	if(e->RowIndex>0) dataGridView2->Rows[e->RowIndex-1]->HeaderCell->ToolTipText  = "";
	dataGridView2->Rows[e->RowIndex]->HeaderCell->ToolTipText  = "Add New Interaction";
	
	//Set the last cell of the row the bin icon
	((DataGridViewImageCell ^)dataGridView2[7,e->RowIndex])->ValueIsIcon=true;
	((DataGridViewImageCell ^)dataGridView2[7,e->RowIndex])->Value =
		(cli::safe_cast<System::Drawing::Icon^  >(MyResources2->GetObject(L"$this.Icon")));

}

System::Void SpinachGUI::MainForm::dataGridView2_CellEndEdit(System::Object^  sender, System::Windows::Forms::DataGridViewCellEventArgs^  e) 
{
	if (e->ColumnIndex==2 && 
		(String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value!="") //insert Interaction
	{
		if(insertInter)
		{
			int jj=Convert::ToInt32((String^)dataGridView2[2,datagridview2_row]->Value);
			Atom^ nAtom=((Atom^)SystemModel->AtomCollection[jj]);

			//Assing initial values of tensor
			::Matrix3x3 ^matrix=gcnew ::Matrix3x3();
			matrix[0]=0.0; matrix[4]=0.0; matrix[8]=0.0;
			matrix[1]=0.0; matrix[2]=0.0; matrix[3]=0.0;
			matrix[5]=0.0; matrix[6]=0.0; matrix[7]=0.0;

			Tensor^ nInter;

			//Combo box for kinds of interactions
			DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
			if(nAtom->isotope->Element=="e")
			{			
				combobox->Items->Add("CHI-tensor");					
				combobox->Items->Add("Zero-Field");
				combobox->Items->Add("G-tensor");						
				if(SystemModel->AtomCollection->get_electron_number()>1)combobox->Items->Add("Exchange");
			}
			else if(nAtom->isotope->Element!="e")
			{
				if(SystemModel->AtomCollection->get_electron_number()) combobox->Items->Add("HFC"); //If electron exist have HFC
				combobox->Items->Add("Shift");
				if(SystemModel->AtomCollection->Count>1) combobox->Items->Add("J-coupling"); //More than 1 atoms
				//Not available for 1/2 spin atoms
				if(nAtom->isotope->Spin!=0.5) combobox->Items->Add("Quadrupolar");
			}
			if(nAtom->isotope->Element=="chi")
			{
				combobox->Items->Add("CHI-tensor");					
				combobox->Items->Add("Zero-Field");
				combobox->Items->Add("G-tensor");
			}

			this->dataGridView2[3,datagridview2_row]=combobox;

			//Create first the comboBox with the options of reference frames
			DataGridViewComboBoxCell^ refcombobox=gcnew DataGridViewComboBoxCell();
			for each(int j in SystemModel->RefFrameCollection->Keys) 
					refcombobox->Items->Add(Convert::ToString(j));
			dataGridView2[5,datagridview2_row]=refcombobox;
			//Select default reference frame
			dataGridView2[5,datagridview2_row]->Value=refcombobox->Items[0];


			
			if(nAtom->isotope->Element!="e") 
			{
				nInter=gcnew Tensor(nAtom,nAtom, InteractionKind::Shift, matrix);	
				nInter->unit=Units::ppm;
				//Set reference frame to the interaction
			    nInter->Frame=SystemModel->RefFrameCollection[1];
				//Add interaction to system
				SystemModel->InteractionCollection->Add(nInter);
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("Shift");
				combobox=UpdateCoupledAtomIDComboBox(SystemModel->InteractionCollection->Count,"Shift");

			}
			else if (nAtom->isotope->Element="e")
			{
				nInter=gcnew Tensor(nAtom,nAtom, InteractionKind::GTensor, matrix);
				nInter->unit=Units::Mi_b;
				//Set reference frame to the interaction
			    nInter->Frame=SystemModel->RefFrameCollection[1];
				//Add interaction to system
			    SystemModel->InteractionCollection->Add(nInter);
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("G-tensor");
				combobox=UpdateCoupledAtomIDComboBox(SystemModel->InteractionCollection->Count,"G-tensor");

			}			
			else if (nAtom->isotope->Element="chi")
			{
				nInter=gcnew Tensor(nAtom,nAtom, InteractionKind::CHITensor, matrix);
				nInter->unit=Units::Mi_b;
				//Set reference frame to the interaction
			    nInter->Frame=SystemModel->RefFrameCollection[1];
				//Add interaction to system
			    SystemModel->InteractionCollection->Add(nInter);
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("CHI-tensor");
				combobox=UpdateCoupledAtomIDComboBox(SystemModel->InteractionCollection->Count,"CHI-tensor");

			};

			//Change kind of interaction and update B atoms menus
			this->dataGridView2[4,datagridview2_row]=combobox;
			//Set the value to defaults
			dataGridView2[4,datagridview2_row]->Value=combobox->Items[0];

			//Assign the ID
			dataGridView2[0,e->RowIndex]->Value=nInter->ID;

			//Change to readable
			dataGridView2[1,e->RowIndex]->ReadOnly=false;
			dataGridView2[2,e->RowIndex]->ReadOnly=false;
			dataGridView2[3,e->RowIndex]->ReadOnly=false;
			dataGridView2[4,e->RowIndex]->ReadOnly=false;
			dataGridView2[5,e->RowIndex]->ReadOnly=false;
			dataGridView2[6,e->RowIndex]->ReadOnly=false;
		
		}
		else //Not Inserting
		{
			//Find interaction ID
			int jj=Convert::ToInt32(dataGridView2[0,datagridview2_row]->Value);
			

           //Temporary change to spirotation in order to change to an  valid  atom
	       ((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::spinrotation;

			//Change atoms
			int ii=Convert::ToInt32((String^)dataGridView2[2,datagridview2_row]->Value);
			((Interaction^ )SystemModel->InteractionCollection[jj])->A=	
				((Atom^)SystemModel->AtomCollection[ii]);

			//Combo box for kinds of interactions
			DataGridViewComboBoxCell^ combobox=UpdateInteractionTypeComboBox(jj);
			this->dataGridView2[3,datagridview2_row]=combobox;
			//Set the value to defaults
			if(((Interaction^ )SystemModel->InteractionCollection[jj])->A->isotope->Element!="e") 
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("Shift");
			else if(((Interaction^ )SystemModel->InteractionCollection[jj])->A->isotope->Element="e")  
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("G-tensor");					
			else if(((Interaction^ )SystemModel->InteractionCollection[jj])->A->isotope->Element="chi")  
				dataGridView2[3,e->RowIndex]->Value=Convert::ToString("CHI-tensor");

			//Change kind of interaction and update B atoms menus
			DataGridViewComboBoxCell^ tcombobox=UpdateCoupledAtomIDComboBox(jj, 
				(String ^)dataGridView2[3,datagridview2_row]->Value);
			this->dataGridView2[4,datagridview2_row]=tcombobox;
			//Set the value to defaults
			dataGridView2[4,datagridview2_row]->Value=tcombobox->Items[0];
			
			//Set this value to the system
			int kk=Convert::ToInt32((String^)dataGridView2[4,datagridview2_row]->Value);
			((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[kk]);

		}

	}
	else if (e->ColumnIndex==3 &&
		(String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value!="") //Change Interaction
	{
		//Find interaction ID
		int jj=Convert::ToInt32(dataGridView2[0,datagridview2_row]->Value);

		//Change kind of interaction and update B atoms menus
		DataGridViewComboBoxCell^ combobox=UpdateCoupledAtomIDComboBox(jj, 
			(String ^)dataGridView2[3,datagridview2_row]->Value);
		this->dataGridView2[4,datagridview2_row]=combobox;
		dataGridView2[4,datagridview2_row]->Value=combobox->Items[0];

		//Set this value to the system
		int kk=Convert::ToInt32((String^)dataGridView2[4,datagridview2_row]->Value);
			((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[kk]);


	}

		else if (e->ColumnIndex==4 &&
		(String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value!="") //Change coupled atom
	{
		//Find interaction ID
		int jj=Convert::ToInt32(dataGridView2[0,datagridview2_row]->Value);

		//Set this value to the system
		int kk=Convert::ToInt32((String^)dataGridView2[4,datagridview2_row]->Value);
			((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[kk]);
	}
	else if (e->ColumnIndex==5 &&
		(String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value!="") //Change reference frame
	{
			
        //Find interaction ID
		int jj=Convert::ToInt32(dataGridView2[0,datagridview2_row]->Value);

		//Set this value to the system
		int kk=Convert::ToInt32((String^)dataGridView2[5,datagridview2_row]->Value);
		((Tensor^ )SystemModel->InteractionCollection[jj])->Frame= ((ReferenceFrame ^)SystemModel->RefFrameCollection[kk]);
	}

	else if (e->ColumnIndex==1 &&
		(String^)dataGridView2[e->ColumnIndex,e->RowIndex]->Value!="") //Change Label
		{
		//Find interaction ID
		int jj=Convert::ToInt32((String^)dataGridView2[0,datagridview2_row]->Value);
		
		((Interaction^ )SystemModel->InteractionCollection[jj])->Label=	
										((String^)dataGridView2[1,e->RowIndex]->Value);
	};

	CheckExistentInteractions(true);
	dataGridView2[e->ColumnIndex,e->RowIndex]->Style->BackColor=System::Drawing::SystemColors::Window;

	 //OpenGL->Render();
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

DataGridViewComboBoxCell^ SpinachGUI::MainForm::UpdateInteractionTypeComboBox(int InteractionIndex)
{
	DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
	int jj=InteractionIndex;
	if(((Interaction^)SystemModel->InteractionCollection[jj])->A->isotope->Element=="e")
	{		
		combobox->Items->Add("CHI-tensor");
		combobox->Items->Add("Zero-Field");
		combobox->Items->Add("G-tensor");
		if(SystemModel->AtomCollection->get_electron_number()>1) combobox->Items->Add("Exchange");
	}
	else if(((Interaction^)SystemModel->InteractionCollection[jj])->A->isotope->Element!="e")
	{
		if(SystemModel->AtomCollection->get_electron_number()) combobox->Items->Add("HFC"); //If electron exist have HFC
		combobox->Items->Add("Shift");
		if(SystemModel->AtomCollection->Count>1) combobox->Items->Add("J-coupling"); //More than 1 atoms
		//Not available for 1/2 spin atoms
		if(((Interaction^)SystemModel->InteractionCollection[jj])->A->isotope->Spin!=0.5) 
			combobox->Items->Add("Quadrupolar");
	}	
	if(((Interaction^)SystemModel->InteractionCollection[jj])->A->isotope->Element=="chi")
	{
		combobox->Items->Add("CHI-tensor");
		combobox->Items->Add("Zero-Field");
		combobox->Items->Add("G-tensor");
		combobox->Items->Add("HFC");

	}
	return combobox;

}

DataGridViewComboBoxCell^ SpinachGUI::MainForm::UpdateCoupledAtomIDComboBox(int InteractionIndex, String^ IntKind)
{
	DataGridViewComboBoxCell^ combobox=gcnew DataGridViewComboBoxCell();
	int jj=InteractionIndex;
	//Temporary change to spirotation in order to change to an  valid  atom
	((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::spinrotation;

	if(IntKind=="HFC")
	{
		
		for each(int j in SystemModel->AtomCollection->Keys) 
		{ 
			if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element=="e")
				combobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
		}
				//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::HFC;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::Gauss;


	}
	else if(IntKind=="Shift")
	{

		combobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID));
		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);
		
		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::Shift;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::ppm;

	}
	else if(IntKind=="J-coupling")
	{

		for each(int j in SystemModel->AtomCollection->Keys)
		{ 
			if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element!="e" &&
				((Atom^ )SystemModel->AtomCollection[j])->ID!=
				((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID)
				combobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
		};

		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::Jcoupling;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::Hz;
	}
	else if(IntKind=="Quadrupolar")
	{
		combobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID));

		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::Quadrupolar;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::MHz;
	}
	else if(IntKind=="G-tensor")
	{
		combobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID));

		
		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::GTensor;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::Mi_b;
	}
	else if(IntKind=="Exchange")
	{
		for each(int j in SystemModel->AtomCollection->Keys)
		{ 
			if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element=="e" &&
				((Atom^ )SystemModel->AtomCollection[j])->ID!=
				((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID)
				combobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
		};

		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::Exchange;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::Mi_b;

	}
	else if(IntKind=="Zero-Field")
	{

		combobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID));

		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::ZFS;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::MHz;
	}		
	else if(IntKind=="CHI-tensor")
	{

		combobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[jj])->A->ID));

		//Set this value to the system
		((Interaction^ )SystemModel->InteractionCollection[jj])->B=	
				((Atom^)SystemModel->AtomCollection[Convert::ToInt32((String^)combobox->Items[0])]);

		((Interaction^)SystemModel->InteractionCollection[jj])->IntKind=InteractionKind::CHITensor;
		((Interaction^)SystemModel->InteractionCollection[jj])->unit=Units::MHz;
	}

	return combobox;
}

System::Void SpinachGUI::MainForm::DataGridView_Interactions_Update() 
{


	int jj=0;
	OpenGL->UpdateDisplay(UpdateType::ALL);
	CheckExistentInteractions(true);
	//In order to clear the first line and update with the new atom dorp menu
	dataGridView2->Rows->Clear();


	for each(int i in SystemModel->InteractionCollection->Keys)
	{
		//Fill Table with Interactions but no Bonds
		if(((Interaction^)SystemModel->InteractionCollection[i])->IntKind!=InteractionKind::CBond)
		{
			dataGridView2->Rows->Add();

			//Interaction ID
			dataGridView2[0,jj]->Value=((Interaction^)SystemModel->InteractionCollection[i])->getID();

			//Atom A ID
			dataGridView2[2,jj]->Value=Convert::ToString(((Interaction^)SystemModel->InteractionCollection[i])->A->ID);

			//Combo box for kinds of interactions
			DataGridViewComboBoxCell^ combobox=UpdateInteractionTypeComboBox(i);
	    	this->dataGridView2[3,jj]=combobox;


			// Kind of Interaction
			//Create first the comboBox with the options of Atom B ID
			DataGridViewComboBoxCell^ ncombobox=gcnew DataGridViewComboBoxCell();


			if(((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::HFC)
			{
				dataGridView2[3,jj]->Value="HFC";
				for each(int j in SystemModel->AtomCollection->Keys)
				{ 
					if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element=="e")
						ncombobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
				};
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::Shift)
			{
				dataGridView2[3,jj]->Value="Shift";
				ncombobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[i])->A->ID));
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::Jcoupling)
			{
				dataGridView2[3,jj]->Value="J-coupling";
				for each(int j in SystemModel->AtomCollection->Keys)
				{ 
					if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element!="e" &&
						((Atom^ )SystemModel->AtomCollection[j])->ID!=
						((Interaction^ )SystemModel->InteractionCollection[i])->A->ID)
						ncombobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
				};
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::Quadrupolar)
			{
				dataGridView2[3,jj]->Value="Quadrupolar";
				ncombobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[i])->A->ID));
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::GTensor)
			{
				dataGridView2[3,jj]->Value="G-tensor";
				ncombobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[i])->A->ID));
			}			
			//			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::Dipolar)
			//			dataGridView2[3,jj]->Value="Dipolar";
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::Exchange)
			{
				dataGridView2[3,jj]->Value="Exchange";
				for each(int j in SystemModel->AtomCollection->Keys)
				{ 
					if(((Atom^)SystemModel->AtomCollection[j])->isotope->Element=="e" &&
						((Atom^ )SystemModel->AtomCollection[j])->ID!=
						((Interaction^ )SystemModel->InteractionCollection[i])->A->ID)
						ncombobox->Items->Add(Convert::ToString(((Atom^ )SystemModel->AtomCollection[j])->ID));
				};
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::ZFS)
			{
				dataGridView2[3,jj]->Value="Zero-Field";
				ncombobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[i])->A->ID));
			}
			else if (((Interaction^)SystemModel->InteractionCollection[i])->IntKind==InteractionKind::CHITensor)
			{
				dataGridView2[3,jj]->Value="CHI-tensor";
				ncombobox->Items->Add(Convert::ToString(((Interaction^ )SystemModel->InteractionCollection[i])->A->ID));
			};

			
			dataGridView2[4,jj]=ncombobox;


			//Atom B ID
			//Select B Atom
		    if(((Interaction^)SystemModel->InteractionCollection[i])->B!=nullptr) 
				dataGridView2[4,jj]->Value=Convert::ToString(((Interaction^)SystemModel->InteractionCollection[i])->B->ID);
			else dataGridView2[4,jj]->Value=Convert::ToString(((Interaction^)SystemModel->InteractionCollection[i])->A->ID);
			
			//Create first the comboBox with the options of reference frames
			DataGridViewComboBoxCell^ refcombobox=gcnew DataGridViewComboBoxCell();
			for each(int j in SystemModel->RefFrameCollection->Keys) 
					refcombobox->Items->Add(Convert::ToString(j));
			dataGridView2[5,jj]=refcombobox;
			//Select reference frame
			dataGridView2[5,jj]->Value=Convert::ToString(((Tensor^)SystemModel->InteractionCollection[i])->Frame->getID());


			dataGridView2[1,jj]->ReadOnly=false;
			dataGridView2[2,jj]->ReadOnly=false;
			dataGridView2[3,jj]->ReadOnly=false;
			dataGridView2[4,jj]->ReadOnly=false;
			dataGridView2[5,jj]->ReadOnly=false;
			dataGridView2[6,jj]->Value="Edit";
			dataGridView2[6,jj]->ReadOnly=false;
			dataGridView2[7,jj]->ReadOnly=false;

			jj++;
		};

		
	};

	dataGridView2->Sort(dataGridView2->Columns[1],ListSortDirection::Ascending);
	
}

System::Void SpinachGUI::MainForm::dataGridView2_MouseEnter(System::Object^  sender, System::EventArgs^  e) 
{
	dataGridView2->Focus();
}

System::Void SpinachGUI::MainForm::dataGridView2_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) 
{
	dataGridView_Helpers();
}

System::Void SpinachGUI::MainForm::Delegate3Method(System::Object^  sender, System::Windows::Forms::NodeLabelEditEventArgs^  e)
{
	labelflag=false;
	e->Node->BeginEdit();
}


TreeNode^ SpinachGUI::MainForm::FindNodeRecurcively(TreeNode ^Root, String ^Name)
{
	TreeNode^ test;
	if(Root->Name==Name) return Root;
	if(Root->Nodes->Count==0) return nullptr;

	for each(TreeNode ^ node in Root->Nodes)
	{
		test=FindNodeRecurcively(node, Name);
		if(test!=nullptr) return test;
	}

	return nullptr; //For the compiler to not complain
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Trackbar interactions
System::Void SpinachGUI::MainForm::HFCtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->HCfactor=pow(10,HFCtrackBar->Value/10.0);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}

System::Void SpinachGUI::MainForm::CStrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{ 
	if(UseTrackBarEventHandler)
	{
		OpenGL->CSfactor=pow(10.0f,CStrackBar->Value/10.0f);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}

System::Void SpinachGUI::MainForm::BondtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e) 
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->CBfactor=BondtrackBar->Value/100.0;
		double test=2.0*(OpenGL->CBfactor-0.5)*
			            (SystemModel->InteractionCollection->InterKindMax[InteractionKind::CBond]-1.6f)+1.6f;
		test=(test>0?test:0.0f);
		BondColorlabel->Text="BOND < "+(test).ToString("N2")+" An";
		 OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
	}
}

System::Void SpinachGUI::MainForm::JCtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e) 
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->JCfactor=JCtrackBar->Value/100.0;
		double absMax=(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling])<
		           abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling]))*
				   abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling])+
				   (abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling])>
				   abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling]))*
				   abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling]);

		JCColorlabel->Text="J-COUPLING  > "+(OpenGL->JCfactor*absMax).ToString("N2")+" Hz";
		 OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
	}
}

System::Void SpinachGUI::MainForm::GTtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->GTfactor=pow(10,GTtrackBar->Value/10.0);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}

System::Void SpinachGUI::MainForm::QCtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e) 
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->QCfactor=pow(10,QCtrackBar->Value/10.0);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}

System::Void SpinachGUI::MainForm::ECtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->ECfactor=ECtrackBar->Value/100.0;
		double absMax=(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange])<
		           abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange]))*
				   abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange])+
				   (abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange])>
				   abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange]))*
				   abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange]);
		ECColorlabel->Text="EXCHANGE COUPL.> "+(OpenGL->ECfactor*absMax).ToString("N2")+" MHz";
		OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
	}
}

System::Void SpinachGUI::MainForm::ZFtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->ZFfactor=pow(10,ZFtrackBar->Value/10.0);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}

System::Void SpinachGUI::MainForm::CHITtrackBar_Scroll(System::Object^  sender, System::EventArgs^  e)
{
	if(UseTrackBarEventHandler)
	{
		OpenGL->CHITfactor=pow(10,CHITtrackBar->Value/10.0);
		OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//CheckBox interactions
System::Void SpinachGUI::MainForm::HFCcheckBox_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->HCFlag=HFCcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::CScheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->CSFlag=CScheckBox->Checked;
	 OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::BondcheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->CBFlag=BondcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
}

System::Void SpinachGUI::MainForm::JCcheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->JCFlag=JCcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
}

System::Void SpinachGUI::MainForm::GTcheckBox_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->GTFlag=GTcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::ECcheckBox_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->ECFlag=ECcheckBox->Checked;
	 OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
}

System::Void SpinachGUI::MainForm::ZFcheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->ZFFlag=ZFcheckBox->Checked;
	 OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::CHITcheckBox_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->CHITFlag=CHITcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::QCcheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->QCFlag=QCcheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}


System::Void SpinachGUI::MainForm::TensorButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	if(Convert::ToInt32((String^)(((ToolStripButton ^)sender)->Tag))==1) //ALL
	{

		GTcheckBox->Checked=OpenGL->GTFlag=true;		
		CHITcheckBox->Checked=OpenGL->CHITFlag=true;
		CScheckBox->Checked=OpenGL->CSFlag=true;
		HFCcheckBox->Checked=OpenGL->HCFlag=true;
		BondcheckBox->Checked=OpenGL->CBFlag=true;
		JCcheckBox->Checked=OpenGL->JCFlag=true;
		//				 DCcheckBox->Checked=OpenGL->DCFlag=true;
		QCcheckBox->Checked=OpenGL->QCFlag=true;
		ECcheckBox->Checked=OpenGL->ECFlag=true;
		ZFcheckBox->Checked=OpenGL->ZFFlag=true;

	}
	else if(Convert::ToInt32((String^)(((ToolStripButton ^)sender)->Tag))==2) //NMR
	{

		GTcheckBox->Checked=OpenGL->GTFlag=false;		
		CHITcheckBox->Checked=OpenGL->CHITFlag=false;
		CScheckBox->Checked=OpenGL->CSFlag=true;
		HFCcheckBox->Checked=OpenGL->HCFlag=false;
		BondcheckBox->Checked=OpenGL->CBFlag=true;
		JCcheckBox->Checked=OpenGL->JCFlag=true;
		//				 DCcheckBox->Checked=OpenGL->DCFlag=true;
		QCcheckBox->Checked=OpenGL->QCFlag=true;
		ECcheckBox->Checked=OpenGL->ECFlag=false;
		ZFcheckBox->Checked=OpenGL->ZFFlag=false;
	}

	else if(Convert::ToInt32((String^)(((ToolStripButton ^)sender)->Tag))==3) //EPR
	{

		GTcheckBox->Checked=OpenGL->GTFlag=true;		
		CHITcheckBox->Checked=OpenGL->CHITFlag=true;		
		CScheckBox->Checked=OpenGL->CSFlag=false;
		HFCcheckBox->Checked=OpenGL->HCFlag=true;
		BondcheckBox->Checked=OpenGL->CBFlag=true;
		JCcheckBox->Checked=OpenGL->JCFlag=false;
		//				 DCcheckBox->Checked=OpenGL->DCFlag=true;
		QCcheckBox->Checked=OpenGL->QCFlag=true;
		ECcheckBox->Checked=OpenGL->ECFlag=true;
		ZFcheckBox->Checked=OpenGL->ZFFlag=true;
	};

	//OpenGL->Render();
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);

}

System::Void SpinachGUI::MainForm::EigenAxescheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->EigenAxesFlag=EigenAxescheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::EigenEllipsoidscheckBox_Click(System::Object^  sender, System::EventArgs^  e)
{
	OpenGL->EigenEllipsoidsFlag=EigenEllipsoidscheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
//ColorDialog interactions
System::Void SpinachGUI::MainForm::Colour_DoubleClick(System::Object^  sender, System::EventArgs^  e) 
{


	if (  GenColorDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		Update_OpenGL_Color(((System::Windows::Forms::Label ^)sender)->Text, GenColorDialog->Color, true );
		Update_Interactions_Color();
		tableLayoutPanel7->Refresh();
	}

}

System::Void SpinachGUI::MainForm::Colorlabel_MouseDoubleClick(System::Object^  sender, System::Windows::Forms::MouseEventArgs^  e)
{
	if (  GenColorDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		Update_OpenGL_Color(((System::Windows::Forms::Label ^)sender)->Text, GenColorDialog->Color, e->Button == ::MouseButtons::Left );
		Update_Interactions_Color();
		tableLayoutPanel7->Refresh();
	}

}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// ToolBox Buttons and checkboxes
System::Void SpinachGUI::MainForm::IsotopesButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	IsotopesDialog^ isotopesdialog = gcnew IsotopesDialog();
	isotopesdialog->ShowDialog();
}

System::Void SpinachGUI::MainForm::HomeButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->Home();
	OpenGL->Render();

}


System::Void SpinachGUI::MainForm::ExitButton_Click(System::Object^  sender, System::EventArgs^  e) 
{
	Application::Exit();
}

System::Void SpinachGUI::MainForm::checkBoxAxes_CheckStateChanged(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->AxesFlag=checkBoxAxes->Checked;
	 OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
}

System::Void SpinachGUI::MainForm::BackGroundColorLabel_Click(System::Object^  sender, System::EventArgs^  e) 
{
	if (  GenColorDialog->ShowDialog() == System::Windows::Forms::DialogResult::OK )
	{
		BackGroundColorLabel->BackColor =GenColorDialog->Color;
		OpenGL->BackgroundColor[0]=BackGroundColorLabel->BackColor.R/255.0f;
		OpenGL->BackgroundColor[1]=BackGroundColorLabel->BackColor.G/255.0f;
		OpenGL->BackgroundColor[2]=BackGroundColorLabel->BackColor.B/255.0f;
		OpenGL->Render();
	}
}

System::Void SpinachGUI::MainForm::SelectedInteractionscheckBox_Click(System::Object^  sender, System::EventArgs^  e) 
{
	OpenGL->SelectedAtomsInteractionsFlag=SelectedInteractionscheckBox->Checked;
	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);
}

System::Void SpinachGUI::MainForm::RotateToPlaneClick(System::Object^  sender, System::EventArgs^  e) 
{
	if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==1) OpenGL->RotateToPlane('X','Y');
	else if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==2) OpenGL->RotateToPlane('X','Z');
	else if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==3) OpenGL->RotateToPlane('Z','Y');
	else if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==4) OpenGL->RotateToPlane('Y','X');
	else if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==5) OpenGL->RotateToPlane('Z','X');
	else if(Convert::ToInt32((String^)(((Button^)sender)->Tag))==6) OpenGL->RotateToPlane('Y','Z');
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Other
System::Void SpinachGUI::MainForm::OnMouseDownOpenGL(System::Object^  sender, System::Windows::Forms::MouseEventArgs^  e)
{

	if (e->Button == ::MouseButtons::Left) 
	{
		this->pictureBoxMouse->Image=
			(cli::safe_cast<System::Drawing::Image^ > (MyResources->GetObject(L"mouseSelectLeft.Image")));
		StatusBarLabel->Text="Rotation";
	}
	else if (e->Button == ::MouseButtons::Right)
	{
		this->pictureBoxMouse->Image=
			(cli::safe_cast<System::Drawing::Image^ > (MyResources->GetObject(L"mouseSelectRight.Image")));
		StatusBarLabel->Text="Translation";
	}
	else if (e->Button == ::MouseButtons::Middle)
	{
		this->pictureBoxMouse->Image=
			(cli::safe_cast<System::Drawing::Image^ > (MyResources->GetObject(L"mouseSelectScroll.Image")));
		StatusBarLabel->Text="Zoom";
	};
}

System::Void SpinachGUI::MainForm::OnMouseUpOpenGL(System::Object^  sender, System::Windows::Forms::MouseEventArgs^  e)
{
	this->pictureBoxMouse->Image=
		(cli::safe_cast<System::Drawing::Image^ > (MyResources->GetObject(L"pictureBoxMouse.Image")));
	StatusBarLabel->Text="";

}

System::Void SpinachGUI::MainForm::ToolTips_Popup(System::Object^  sender, System::Windows::Forms::PopupEventArgs^  e) 
{ 
	StatusBarLabel->Text=ToolTips->GetToolTip(e->AssociatedControl);
}

System::Void SpinachGUI::MainForm::OnMouseWheel(System::Object^  sender, System::Windows::Forms::MouseEventArgs^  e)
{
	if(OpenGL->focused) OpenGL->OnMouseWheel(sender,e);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Panel Paint interactions


System::Void SpinachGUI::MainForm::Panel_Paint_Gradient(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  pe)
{
	Graphics^ g = pe->Graphics;
	System::Drawing::Rectangle myRectangle = ((Panel^)sender)->ClientRectangle;
	int enabledcolor=130;


		

/*

		System::Drawing::Drawing2D::LinearGradientBrush^ myLinearGradientBrush = 
			gcnew System::Drawing::Drawing2D::LinearGradientBrush( myRectangle, acolor, bcolor,  
			System::Drawing::Drawing2D::LinearGradientMode::Horizontal);

		g->FillRectangle(myLinearGradientBrush, myRectangle);


		System::Drawing::Drawing2D::HatchBrush^ myHatchBrush = 
			gcnew System::Drawing::Drawing2D::HatchBrush(System::Drawing::Drawing2D::HatchStyle::WideUpwardDiagonal,
			Color::Gray, Color::Transparent);

		g->FillRectangle(myHatchBrush, myRectangle);
		*/
	
		Color acolor=Color::FromArgb(
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[0])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125),
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[1])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125),
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[2])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125));

	Color bcolor=Color::FromArgb(
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[3])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125),
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[4])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125),
		(int)(Convert::ToDouble((Double ^)((ArrayList ^)((Panel^)sender)->Tag)[5])*
		                       (((Panel^)sender)->Enabled?170:130))+(((Panel^)sender)->Enabled?85:125));

			System::Drawing::Drawing2D::LinearGradientBrush^ myLinearGradientBrush = 
			gcnew System::Drawing::Drawing2D::LinearGradientBrush( myRectangle, acolor, bcolor,  
			System::Drawing::Drawing2D::LinearGradientMode::Horizontal);

		g->FillRectangle(myLinearGradientBrush, myRectangle);

        //if(JCpanel)JCColorlabel->ForeColor=Color::LightGray; else JCColorlabel->ForeColor=Color::Black;
		//if(ECpanel)ECColorlabel->ForeColor=Color::LightGray; else ECColorlabel->ForeColor=Color::Black;
}

System::Void SpinachGUI::MainForm::Update_OpenGL_Color(String^ text, Color^ acolor, bool left)
   {

	//Color
	if(text->Contains("CHEMICAL SHIFT"))
	{
	OpenGL->CScolor[0]=acolor->R/255.0f;
	OpenGL->CScolor[1]=acolor->G/255.0f;
	OpenGL->CScolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("BOND"))
	{
	OpenGL->CBcolor[0]=acolor->R/255.0f;
	OpenGL->CBcolor[1]=acolor->G/255.0f;
	OpenGL->CBcolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("J-COUPLING"))
	{
		if(left)
		{
			OpenGL->JCcolor[0]=acolor->R/255.0f;
			OpenGL->JCcolor[1]=acolor->G/255.0f;
			OpenGL->JCcolor[2]=acolor->B/255.0f;
		}
		else
		{
			OpenGL->JCcolor[3]=acolor->R/255.0f;
			OpenGL->JCcolor[4]=acolor->G/255.0f;
			OpenGL->JCcolor[5]=acolor->B/255.0f;
		}
	}

		if(text->Contains("EXCHANGE"))
	{
		if(left)
		{
			OpenGL->ECcolor[0]=acolor->R/255.0f;
			OpenGL->ECcolor[1]=acolor->G/255.0f;
			OpenGL->ECcolor[2]=acolor->B/255.0f;
		}
		else
		{
			OpenGL->ECcolor[3]=acolor->R/255.0f;
			OpenGL->ECcolor[4]=acolor->G/255.0f;
			OpenGL->ECcolor[5]=acolor->B/255.0f;
		}
	}
	
	if(text->Contains("HYPERFINE"))
	{
	OpenGL->HCcolor[0]=acolor->R/255.0f;
	OpenGL->HCcolor[1]=acolor->G/255.0f;
	OpenGL->HCcolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("QUADRUPOLAR"))
	{
	OpenGL->QCcolor[0]=acolor->R/255.0f;
	OpenGL->QCcolor[1]=acolor->G/255.0f;
	OpenGL->QCcolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("G-TENSOR"))
	{
	OpenGL->GTcolor[0]=acolor->R/255.0f;
	OpenGL->GTcolor[1]=acolor->G/255.0f;
	OpenGL->GTcolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("ZERO-FIELD"))
	{
	OpenGL->ZFcolor[0]=acolor->R/255.0f;
	OpenGL->ZFcolor[1]=acolor->G/255.0f;
	OpenGL->ZFcolor[2]=acolor->B/255.0f;
	}

	if(text->Contains("CHI-TENSOR"))
	{
	OpenGL->CHITcolor[0]=acolor->R/255.0f;
	OpenGL->CHITcolor[1]=acolor->G/255.0f;
	OpenGL->CHITcolor[2]=acolor->B/255.0f;
	}

	OpenGL->UpdateDisplay(UpdateType::ELLIPSOIDS);
	OpenGL->UpdateDisplay(UpdateType::BONDS_LIKE);


   }

System::Void SpinachGUI::MainForm::Update_Interactions_Color()
   {
	Color acolor;

	//HFC color
	acolor=Color::FromArgb( (int)(OpenGL->HCcolor[0]*(HFCpanel->Enabled?170:130))+(HFCpanel->Enabled?85:125),
								  (int)(OpenGL->HCcolor[1]*(HFCpanel->Enabled?170:130))+(HFCpanel->Enabled?85:125),
								  (int)(OpenGL->HCcolor[2]*(HFCpanel->Enabled?170:130))+(HFCpanel->Enabled?85:125));

	HFCpanel->BackColor=acolor;HFCColorlabel->BackColor=acolor;
	HFCcheckBox->BackColor=acolor;HFCtrackBar->BackColor=acolor;HFCtrackBar->BorderColor=acolor;
	HFCColorlabel->ForeColor=Color::LightGray;

	//CS Color
	acolor=Color::FromArgb( (int)(OpenGL->CScolor[0]*(CSpanel->Enabled?170:130))+(CSpanel->Enabled?85:125),
	 					    (int)(OpenGL->CScolor[1]*(CSpanel->Enabled?170:130))+(CSpanel->Enabled?85:125),
							(int)(OpenGL->CScolor[2]*(CSpanel->Enabled?170:130))+(CSpanel->Enabled?85:125));

	CSpanel->BackColor=acolor;CSColorlabel->BackColor=acolor;
	CScheckBox->BackColor=acolor;CStrackBar->BackColor=acolor;CStrackBar->BorderColor=acolor;
	CSColorlabel->ForeColor=Color::LightGray;

	//CBond Color
	acolor=Color::FromArgb( (int)(OpenGL->CBcolor[0]*(Bondpanel->Enabled?170:130))+(Bondpanel->Enabled?85:125),
	 					    (int)(OpenGL->CBcolor[1]*(Bondpanel->Enabled?170:130))+(Bondpanel->Enabled?85:125),
							(int)(OpenGL->CBcolor[2]*(Bondpanel->Enabled?170:130))+(Bondpanel->Enabled?85:125));

	Bondpanel->BackColor=acolor;BondColorlabel->BackColor=acolor;
	BondcheckBox->BackColor=acolor;BondtrackBar->BackColor=acolor;BondtrackBar->BorderColor=acolor;
	BondColorlabel->ForeColor=Color::LightGray;
	BondtrackBar_Scroll(gcnew System::Object(), gcnew System::EventArgs()); 
	
	//JC Color	
	JCColorlabel->Tag=ConColor(OpenGL->JCcolor);JCpanel->Tag=ConColor(OpenGL->JCcolor);
	JCColorlabel->BackColor=Color::FromArgb(1,1,1,1);
	if(JCpanel->Enabled) JCColorlabel->ForeColor=Color::LightGray;
	else JCColorlabel->ForeColor=Color::Black;
	JCtrackBar_Scroll(gcnew System::Object(), gcnew System::EventArgs()); 

	//EC Color
	ECColorlabel->Tag=ConColor(OpenGL->ECcolor); ECpanel->Tag=ConColor(OpenGL->ECcolor);
	ECColorlabel->BackColor=Color::FromArgb(1,1,1,1);
	if(ECpanel->Enabled) ECColorlabel->ForeColor=Color::LightGray;
	else ECColorlabel->ForeColor=Color::Black;
	ECtrackBar_Scroll(gcnew System::Object(), gcnew System::EventArgs()); 

	//QC Color
	acolor=Color::FromArgb( (int)(OpenGL->QCcolor[0]*(QCpanel->Enabled?170:130))+(QCpanel->Enabled?85:125),
	 					    (int)(OpenGL->QCcolor[1]*(QCpanel->Enabled?170:130))+(QCpanel->Enabled?85:125),
							(int)(OpenGL->QCcolor[2]*(QCpanel->Enabled?170:130))+(QCpanel->Enabled?85:125));

	QCpanel->BackColor=acolor;QCColorlabel->BackColor=acolor;
	QCcheckBox->BackColor=acolor;QCtrackBar->BackColor=acolor;QCtrackBar->BorderColor=acolor;
	QCColorlabel->ForeColor=Color::LightGray;

	//GT Color
	acolor=Color::FromArgb( (int)(OpenGL->GTcolor[0]*(GTpanel->Enabled?170:130))+(GTpanel->Enabled?85:125),
	 					    (int)(OpenGL->GTcolor[1]*(GTpanel->Enabled?170:130))+(GTpanel->Enabled?85:125),
							(int)(OpenGL->GTcolor[2]*(GTpanel->Enabled?170:130))+(GTpanel->Enabled?85:125));

	
	GTpanel->BackColor=acolor;GTColorlabel->BackColor=acolor;
	GTcheckBox->BackColor=acolor;GTtrackBar->BackColor=acolor;GTtrackBar->BorderColor=acolor;
	GTColorlabel->ForeColor=Color::LightGray;

	//ZF Color
	acolor=Color::FromArgb( (int)(OpenGL->ZFcolor[0]*(ZFpanel->Enabled?170:130))+(ZFpanel->Enabled?85:125),
	 					    (int)(OpenGL->ZFcolor[1]*(ZFpanel->Enabled?170:130))+(ZFpanel->Enabled?85:125),
							(int)(OpenGL->ZFcolor[2]*(ZFpanel->Enabled?170:130))+(ZFpanel->Enabled?85:125));

	ZFpanel->BackColor=acolor;ZFColorlabel->BackColor=acolor;
	ZFcheckBox->BackColor=acolor;ZFtrackBar->BackColor=acolor;ZFtrackBar->BorderColor=acolor;
	ZFColorlabel->ForeColor=Color::LightGray;
	
	//CHIT Color
	acolor=Color::FromArgb( (int)(OpenGL->CHITcolor[0]*(CHITpanel->Enabled?170:130))+(CHITpanel->Enabled?85:125),
	 					    (int)(OpenGL->CHITcolor[1]*(CHITpanel->Enabled?170:130))+(CHITpanel->Enabled?85:125),
							(int)(OpenGL->CHITcolor[2]*(CHITpanel->Enabled?170:130))+(CHITpanel->Enabled?85:125));

	
	CHITpanel->BackColor=acolor;CHITColorlabel->BackColor=acolor;
	CHITcheckBox->BackColor=acolor;CHITtrackBar->BackColor=acolor;CHITtrackBar->BorderColor=acolor;
	CHITColorlabel->ForeColor=Color::LightGray;

   }

System::Void SpinachGUI::MainForm::trackBar_EnabledChanged(System::Object^  sender, System::EventArgs^  e) 
{
	if(((gTrackBar::gTrackBar^)sender)->Enabled)
	{
		((gTrackBar::gTrackBar^)sender)->SliderColorHigh->ColorA=System::Drawing::Color::LightGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorHigh->ColorB=System::Drawing::Color::LightGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorLow->ColorA=System::Drawing::Color::LightGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorLow->ColorB=System::Drawing::Color::LightGray;
		((gTrackBar::gTrackBar^)sender)->TickColor=System::Drawing::Color::LightGray;
	}
	else
	{
		((gTrackBar::gTrackBar^)sender)->SliderColorHigh->ColorA=System::Drawing::Color::DarkGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorHigh->ColorB=System::Drawing::Color::DarkGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorLow->ColorA=System::Drawing::Color::DarkGray;
		((gTrackBar::gTrackBar^)sender)->SliderColorLow->ColorB=System::Drawing::Color::DarkGray;
		((gTrackBar::gTrackBar^)sender)->TickColor=System::Drawing::Color::DarkGray;
	}

}


ArrayList^ SpinachGUI::MainForm::ConColor(double* matrix)
{
	ArrayList ^ result=gcnew ArrayList();
	for (int i=0;i<6;i++) { result->Add(matrix[i]);}
	return result;

}

System::Void SpinachGUI::MainForm::Reset()
{
	//trackbars
	BondtrackBar->Value=50;
	JCtrackBar->Value=50;
	ECtrackBar->Value=50;
	CStrackBar->Value=0;
	GTtrackBar->Value=0;	
	CHITtrackBar->Value=0;
	ZFtrackBar->Value=0;
	QCtrackBar->Value=0;
	HFCtrackBar->Value=0;

	//trackbar checkbox
	BondcheckBox->Checked=OpenGL->CBFlag;
	CScheckBox->Checked=OpenGL->CSFlag;
	HFCcheckBox->Checked=OpenGL->HCFlag;
	GTcheckBox->Checked=OpenGL->GTFlag;	
	CHITcheckBox->Checked=OpenGL->CHITFlag;
	JCcheckBox->Checked=OpenGL->JCFlag;
	QCcheckBox->Checked=OpenGL->QCFlag;
	ECcheckBox->Checked=OpenGL->ECFlag;
	ZFcheckBox->Checked=OpenGL->ZFFlag;
	
	checkBoxAxes->Checked=OpenGL->AxesFlag;
	checkBoxAtomID->Checked=OpenGL->AtomIDFlag;
	EigenAxescheckBox->Checked=OpenGL->EigenAxesFlag;
	EigenEllipsoidscheckBox->Checked=OpenGL->EigenEllipsoidsFlag;
	SelectedInteractionscheckBox->Checked=OpenGL->SelectedAtomsInteractionsFlag;
	Stereobutton->Checked=OpenGL->stereoview;
	BackGroundColorLabel->BackColor=Color::FromArgb((int)(OpenGL->BackgroundColor[0]*255),
													(int)(OpenGL->BackgroundColor[1]*255),
													(int)(OpenGL->BackgroundColor[2]*255));

	CheckExistentInteractions(false);

}

System::Void SpinachGUI::MainForm::CheckExistentInteractions(bool trackbarsReposition)
{
		double validminCB=SystemModel->InteractionCollection->InterKindMin[InteractionKind::CBond]> epsilo && 
		              SystemModel->InteractionCollection->InterKindMin[InteractionKind::CBond]< dMax ? 
					  SystemModel->InteractionCollection->InterKindMin[InteractionKind::CBond]: 1.0f;

	Bondpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::CBond]>0;
	CSpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::Shift]>0;
	JCpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::Jcoupling]>0;
	ECpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::Exchange]>0;
	ZFpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::ZFS]>0;	
	CHITpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::CHITensor]>0; 
	HFCpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::HFC]>0;
	GTpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::GTensor]>0; 	
    QCpanel->Enabled=SystemModel->InteractionCollection->InterKindCount[InteractionKind::Quadrupolar]>0;

	if(trackbarsReposition)
	{
	UseTrackBarEventHandler=false;
	double temp;
   //Chemical shift factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::Shift]>0)
	{
		temp=OpenGL->CSfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Shift])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Shift]) 
			: 1.0f)/validminCB;

		CStrackBar->Value=(int)(10*Math::Log10(temp));
		OpenGL->CSfactor=temp;
	}

	//Hyperfine factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::HFC]>0)
	{
		temp=OpenGL->HCfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::HFC])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::HFC]) 
			: 1.0f)/validminCB;

		HFCtrackBar->Value=(int)(10.0f*Math::Log10(temp));
		OpenGL->HCfactor=temp;
	}

	//Quadrupolar factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::Quadrupolar]>0)
	{
		temp=OpenGL->QCfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Quadrupolar])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Quadrupolar]) 
			: 1.0f)/validminCB;

		QCtrackBar->Value=(int)(10.0f*Math::Log10(temp));
		OpenGL->QCfactor=temp;
	}

	//Gtensor factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::GTensor]>0)
	{
		temp=OpenGL->GTfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::GTensor])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::GTensor]) 
			: 1.0f)/3.0f;

		GTtrackBar->Value=(int)(10.0f*Math::Log10(temp));
		OpenGL->GTfactor=temp;
	}
	
	//ZFS factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::ZFS]>0)
	{
		temp=OpenGL->ZFfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::ZFS])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::ZFS]) 
			: 1.0f)/3.0f;

	   ZFtrackBar->Value=(int)(10.0f*Math::Log10(temp));
	   OpenGL->ZFfactor=temp;
	}

	//CHItensor factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::CHITensor]>0)
	{
		temp=OpenGL->CHITfinfactor*(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::CHITensor])>
			epsilo ?
			(SystemModel->InteractionCollection->InterKindMax[InteractionKind::CHITensor]) 
			: 1.0f)/3.0f;

		CHITtrackBar->Value=(int)(10.0f*Math::Log10(temp));
		OpenGL->CHITfactor=temp;
	}

	//J-coupling factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::Jcoupling]>0)
	{

		double absMax=(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling])<
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling]))*
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling])+
			(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling])>
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Jcoupling]))*
			abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Jcoupling]);

		temp=OpenGL->JCfinfactor/absMax;

		JCtrackBar->Value=(int)(100.0f*temp);
		OpenGL->JCfactor=temp;
	}

		//Exchange coupling factor
	if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::Exchange]>0)
	{

		double absMax=(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange])<
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange]))*
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange])+
			(abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange])>
			abs(SystemModel->InteractionCollection->InterKindMin[InteractionKind::Exchange]))*
			abs(SystemModel->InteractionCollection->InterKindMax[InteractionKind::Exchange]);

		temp=OpenGL->ECfinfactor/absMax;

		ECtrackBar->Value=(int)(100.0f*temp);
		OpenGL->ECfactor=temp;
	}

	//Bond factor
		if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::CBond]>0)
	{
		temp=(OpenGL->CBfinfactor-1.6f)/(2.0*(SystemModel->InteractionCollection->InterKindMax[InteractionKind::CBond]-1.6f))+0.5;

		BondtrackBar->Value=(int)(100.0f*temp);
		OpenGL->CBfactor=temp;
	}

	UseTrackBarEventHandler=true;
	}

	Update_Interactions_Color();
	

}

double* SpinachGUI::MainForm::RevConColor(ArrayList ^ matrix)
{
	double * result=new double[matrix->Count];
	for (int i=0;i<matrix->Count;i++) { result[i]=Convert::ToDouble((Double ^)matrix[i]);}
	return result;

}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//OpenGL context menu

System::Void SpinachGUI::MainForm::OpenGLcontextMenu_ItemClicked(System::Object^  sender, System::Windows::Forms::ToolStripItemClickedEventArgs^  e) 
{
	int k=Convert::ToInt32(e->ClickedItem->Tag);
	orientationdialog->Initialization(((Tensor^)SystemModel->InteractionCollection[k]), OpenGL, 
		                                      gcnew Check(this,&SpinachGUI::MainForm:: CheckExistentInteractions));
	orientationdialog->ShowDialog();

}

System::Void SpinachGUI::MainForm::OpenGLcontextMenu_Closed(System::Object^  , System::Windows::Forms::ToolStripDropDownClosedEventArgs^  ) 
{

	OpenGL->ToBeSelectedAtom=-1;
}

//Thread for import
System::Void SpinachGUI::MainForm::ImportbackgroundWorker_DoWork(System::Object^  sender, System::ComponentModel::DoWorkEventArgs^  e) 
{
	//OpenedFile
	IOSpinSystem^ OpenedFile=(IOSpinSystem^ )e->Argument;
	try{
		e->Result=(IOSpinSystem^ ) e->Argument;
		if(OpenedFile->LoadFile())  {}//e->Result=(IOSpinSystem^ )e->Argument;
		else
		{
			((IOSpinSystem^ )(e->Argument))->ReadingFile->Close();
			e->Cancel=true;
			throw gcnew Exception("File Format is not "+OpenedFile->FormatName+" format!");
		}
	}
	catch(Exception ^ error)
	{
		((IOSpinSystem^ )(e->Argument))->ReadingFile->Close();
		throw gcnew Exception(error->Message);
	}
	catch(String ^ error)
	{
		((IOSpinSystem^ )(e->Argument))->ReadingFile->Close();
		throw gcnew Exception(error);
	}


}

System::Void SpinachGUI::MainForm::ImportbackgroundWorker_RunWorkerCompleted(System::Object^  sender, System::ComponentModel::RunWorkerCompletedEventArgs^  e) 
{
	GenprogressBar->Visible=false;
	this->Enabled=true;
	if(e->Error != nullptr || e->Cancelled)
	{
		MessageBox::Show(e->Error->Message, "Error", 
			MessageBoxButtons::OK, MessageBoxIcon::Error) ;
	}
	else
	{
		//Nameing
		CurrentTitleFile=Path::GetFileNameWithoutExtension( ((IOSpinSystem^ )(e->Result))->FileName);
		CurrentSavedFile=nullptr;
		ModelFileName->Text="Imported File: "+Path::GetFileName( ((IOSpinSystem^ )(e->Result))->FileName);
		this->Text=CurrentTitleFile+" - Spinach GUI "+SpinachGUIver;


		SystemModel=((IOSpinSystem^ )(e->Result))->SystemModel;
		SystemModel->PropertyChanged+=gcnew PropertyChangedEventHandler(this,&MainForm::ModelChange);
		//When importing only atoms it better to declare that a change happen
		ModelChange(sender, gcnew PropertyChangedEventArgs("Nothing")); 
		OpenGL->SystemModel=SystemModel;

		//Filtering
		if(SystemModel->InteractionCollection->InterKindCount[InteractionKind::HFC]>0 ||
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::Jcoupling]>0 ||
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::Quadrupolar]>0 )
		{
			FilterFile^ filterfile = gcnew FilterFile(SystemModel);	
			filterfile->ShowDialog();
		};

		//For Gaussian only
		if(((IOSpinSystem^ )(e->Result))->GetType()->ToString()=="Gauss" &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::HFC]==0 &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::CShielding]==0 &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::Jcoupling]==0 &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::GTensor]==0 &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::CHITensor]==0 &&
			SystemModel->InteractionCollection->InterKindCount[InteractionKind::Quadrupolar]==0  )
		{
			MessageBox::Show("The Gaussian export file doesn't contain any information\n "+
				"about the interactions. Re-run Gaussian with #p parameter.", "Warning", 
				MessageBoxButtons::OK, MessageBoxIcon::Warning) ;
		}

		//If Shielding then Convert to shifts
		if(((IOSpinSystem^ )(e->Result))->ToShift)
		{
			ShieldingtoShift^ converttoshift = gcnew ShieldingtoShift(SystemModel);
			if(converttoshift->ShowDialog()!= System::Windows::Forms::DialogResult::OK)
			{
				SystemModel->AtomCollection->Clear();
				SystemModel->InteractionCollection->Clear();
				SystemModel->RefFrameCollection->Clear();
				CurrentSavedFile="";
				this->Text="Spinach GUI "+SpinachGUIver;
			}
		};


		LoadModel();
		OpenGL->UpdateDisplay(UpdateType::ALL);
		Savebutton->Enabled=true;
	}
}


