#include "../StdAfx.h"
#include "SpinXML.h"

//Definitions
#define To_Double(aNumber) Convert::ToDouble(SpinachGUI::ConvertToString(aNumber, 5, "N"))
#define InteractionCollection  SystemModel->InteractionCollection
#define AtomCollection  SystemModel->AtomCollection

/**
*\file SpinXML.cpp
*/

/**
* Constructor of SpinXML format for reading or writing.
* @param filename Name of the file to be read or write.
* @param model The model where the imported data will be saved or the data will be exported from.
*/
SpinXML::SpinXML(System::String^ filename, FilterType type, Model^% model)
{
 	SystemModel=model;
	FileName=filename;
	FormatName="SpinXML";

	//Depending the filtertype create file for reading or writing
	if(type==FilterType::IMPORT) ReadingFile = gcnew StreamReader(filename);
	else if(type==FilterType::EXPORT) WritingFile = gcnew StreamWriter(filename);
    
}

/**
* Main function for opening and reading file using the auto-generated spinxml schema file
* @return Returns false if the format does not seem to be correct.
*/
bool SpinXML::LoadFile(void)
{
	XmlReader^ reader;

	//Initialization of the spinxml schema, main and reference frmas
	spin_system^ XMLSpinSystem=gcnew spin_system();
	spin_system_ref^ XMLSpinSystemRef=gcnew spin_system_ref();
	XMLSpinSystem->InitVars();
	XMLSpinSystemRef->InitVars();

	//Opening and reading the xml file, checking for any errors
	reader = XmlReader::Create(ReadingFile);
	try  {XMLSpinSystem->ReadXml(reader); }
	catch (::System::InvalidOperationException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message);
	}
	catch (::System::Xml::XmlException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message );
	}
	catch (::System::Data::ConstraintException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message);
	}

	//Close file and reader
	reader->Close();
	ReadingFile->Close();

	//Opening and reading the xml file again, checking for any errors, using reference frame schema
	ReadingFile = gcnew StreamReader(FileName);
	reader = XmlReader::Create(ReadingFile);
	try  {XMLSpinSystemRef->ReadXml(reader); }
	catch (::System::InvalidOperationException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message);
	}
	catch (::System::Xml::XmlException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message );
	}
	catch (::System::Data::ConstraintException^ e) {
		throw gcnew Exception("File : "+FileName+"\n Error in XML Format: "+e->Message);
	}

	//Close file and reader
	reader->Close();
	ReadingFile->Close();


	//Loop over all atoms to import of atoms and coordinates
	for(int i=0;i<XMLSpinSystem->spin->Count;i++)
	{
		Atom^ nAtom=gcnew Atom();
		String ^ mass="";
		String ^element="";
		int value;

		//Import coordinates
		nAtom->X=XMLSpinSystem->coordinates[i]->x;
		nAtom->Y=XMLSpinSystem->coordinates[i]->y;
		nAtom->Z=XMLSpinSystem->coordinates[i]->z;

		//Read each character in the isotope string in order to seperate numerics and characters
		//and find mass number and isotopes
		for(int j=0;j<XMLSpinSystem->spin[i]->isotope->Length;j++)
		{
			if(Int32::TryParse(System::Convert::ToString(XMLSpinSystem->spin[i]->isotope[j]), value))
				mass=mass+System::Convert::ToString(value);
			else
				element=element+System::Convert::ToString(XMLSpinSystem->spin[i]->isotope[j]);
		};
		value=System::Convert::ToInt32(mass);

		//Find the isotope form the element and mass number
		nAtom->isotope=Isotopes::FindIsotope(element,0, value);

		//Import the label if exist
		if(XMLSpinSystem->spin[i]->IslabelNull()) nAtom->Label="";
		else nAtom->Label=XMLSpinSystem->spin[i]->label;

		//Add atom to collection
		AtomCollection->Add(nAtom);
	}

	//Loop over all ref. frame to import of reference frames
	for(int i=0;i<XMLSpinSystemRef->reference_frame->Count;i++)
	{
		//dcm
		::Matrix3x3^ mat=gcnew ::Matrix3x3();
		int ParentID;
		ReferenceFrame^ frame;

		//Loop over direction matrices
		for(int j=0;j<XMLSpinSystemRef->direction->Count;j++)
		{
			//Match the ids of the direction with the reference frame
			if(XMLSpinSystemRef->direction[j]->reference_frameRow->id==XMLSpinSystemRef->reference_frame[i]->id) 
			{
				//Read matrix in mat
				if(XMLSpinSystemRef->direction[j]->GetdcmRows()->Length>0)
				{
					mat[0]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->xx;
					mat[1]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->xy;
					mat[2]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->xz;
					mat[3]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->yx;
					mat[4]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->yy;
					mat[5]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->yz;
					mat[6]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->zx;
					mat[7]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->zy;
					mat[8]=XMLSpinSystemRef->direction[j]->GetdcmRows()[0]->zz;
				};

				//Create ref. frame form the matrix
				frame=gcnew ReferenceFrame(mat);

				//Parent reference frame. If not existing is the root and set it		
				if(XMLSpinSystemRef->reference_frame[i]->Isparent_reference_frame_idNull() || j==0)
				{
					frame->ParentRefFrame=nullptr;
					SystemModel->RefFrameCollection[1]=frame;
				}
				else //other reference frames, add them
				{
					frame->ParentRefFrame=SystemModel->RefFrameCollection[XMLSpinSystemRef->reference_frame[i]->parent_reference_frame_id];
					SystemModel->RefFrameCollection->Add(frame);
				};
			};
		};
	};

	//Loop over all interactions to import of interaction
	for(int i=0;i<XMLSpinSystem->interaction->Count;i++)
	{
		//Search for A atom according to ID
		int AID=XMLSpinSystem->interaction[i]->spin_a;

		//If ID is zero, change to 1 for unit indexing
		if(XMLSpinSystem->interaction[0]->spin_a==0) AID++;

		int BID;

		//If B not existing put equal to A
		if(XMLSpinSystem->interaction[i]->Isspin_bNull()) BID=AID;
		else 
		{
			BID=XMLSpinSystem->interaction[i]->spin_b;

			//If ID is zero, change to 1 for unit indexing
			if(XMLSpinSystem->interaction[0]->spin_a==0) BID++;
		};

		//Set the atoms form the imported collection
		Atom^ A=((Atom ^)AtomCollection[AID]);
		Atom^ B=((Atom ^)AtomCollection[BID]);


		//Parent reference Frame
		ReferenceFrame^ refFrame;

		//If reference not declared use root
		if(XMLSpinSystem->interaction[i]->Isreference_frame_idNull())
			refFrame=SystemModel->RefFrameCollection[1];
		else
			refFrame=SystemModel->RefFrameCollection[XMLSpinSystem->interaction[i]->reference_frame_id];

		//Search of Interaction kind
		InteractionKind IntKind;

		//Check and translate for interaction kind, if does not exist throw exception
		if (XMLSpinSystem->interaction[i]->kind=="hfc") IntKind=InteractionKind::HFC;
		else if (XMLSpinSystem->interaction[i]->kind=="jcoupling") IntKind=InteractionKind::Jcoupling;
		else if (XMLSpinSystem->interaction[i]->kind=="quadrupolar") IntKind=InteractionKind::Quadrupolar;
		else if (XMLSpinSystem->interaction[i]->kind=="gtensor") IntKind=InteractionKind::GTensor;		
		else if (XMLSpinSystem->interaction[i]->kind=="chitensor") IntKind=InteractionKind::CHITensor;
		else if (XMLSpinSystem->interaction[i]->kind=="zfs") IntKind=InteractionKind::ZFS;
		else if (XMLSpinSystem->interaction[i]->kind=="exchange") IntKind=InteractionKind::Exchange;
		else if (XMLSpinSystem->interaction[i]->kind=="dipolar") IntKind=InteractionKind::Dipolar;
		else if (XMLSpinSystem->interaction[i]->kind=="spinrotation") IntKind=InteractionKind::spinrotation;
		else if (XMLSpinSystem->interaction[i]->kind=="shielding") 
		{IntKind=InteractionKind::CShielding; ToShift=true;}
		else if (XMLSpinSystem->interaction[i]->kind=="shift") IntKind=InteractionKind::Shift;
		else throw gcnew Exception("File : "+FileName+"\n Error in XML Format: \"" +
			XMLSpinSystem->interaction[i]->kind+"\" is not an accepted interaction kind!"); 




		//Check if interaction is written in matrix form and save it in a matrix
		::Matrix3x3 ^matrix3x3= gcnew ::Matrix3x3();
		if(XMLSpinSystem->interaction[i]->GettensorRows()->Length>0)
		{
			matrix3x3[0]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->xx;
			matrix3x3[1]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->xy;
			matrix3x3[2]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->xz;
			matrix3x3[3]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->yx;
			matrix3x3[4]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->yy;
			matrix3x3[5]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->yz;
			matrix3x3[6]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->zx;
			matrix3x3[7]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->zy;
			matrix3x3[8]=XMLSpinSystem->interaction[i]->GettensorRows()[0]->zz;
		};

		//Check if interaction is written in eigen values form and save it in a matrix
		double *eigenvalues= new double[3];
		//Eigenvalues
		if(XMLSpinSystem->interaction[i]->GeteigenvaluesRows()->Length>0)
		{
			eigenvalues[0]=XMLSpinSystem->interaction[i]->GeteigenvaluesRows()[0]->xx;
			eigenvalues[1]=XMLSpinSystem->interaction[i]->GeteigenvaluesRows()[0]->yy;
			eigenvalues[2]=XMLSpinSystem->interaction[i]->GeteigenvaluesRows()[0]->zz;
		};

		//Check if interaction is written in Axiality-Rombicity form and 
		// save it in a calculated eigen matrix
		double ax, rh, iso;
		if(XMLSpinSystem->interaction[i]->Getaxiality_rhombicityRows()->Length>0)
		{
			ax=XMLSpinSystem->interaction[i]->Getaxiality_rhombicityRows()[0]->ax;
			rh=XMLSpinSystem->interaction[i]->Getaxiality_rhombicityRows()[0]->rh;
			iso=XMLSpinSystem->interaction[i]->Getaxiality_rhombicityRows()[0]->iso;
			eigenvalues[0]=-ax/6.0f+rh/2.0f+iso;
			eigenvalues[1]=-ax/6.0f-rh/2.0f+iso;
			eigenvalues[2]=ax/3.0f+iso;
		};

		//Check if interaction is written in Span-Skew form and 
		// save it in a calculated eigen matrix
		double span, skew;
		if(XMLSpinSystem->interaction[i]->Getspan_skewRows()->Length>0)
		{
			span=XMLSpinSystem->interaction[i]->Getspan_skewRows()[0]->span;
			skew=XMLSpinSystem->interaction[i]->Getspan_skewRows()[0]->skew;
			iso=XMLSpinSystem->interaction[i]->Getspan_skewRows()[0]->iso;
			eigenvalues[0]=span*skew-span/2.0f;
			eigenvalues[1]=3.0f*iso-2.0f*span*skew;
			eigenvalues[2]=span*skew+span/2.0f;
		};


		//Loop over directions to find respective form of orientation
		double *dcm=new double[9];
		for(int j=0;j<XMLSpinSystem->orientation->Count;j++)
		{
			//Match the ids of the direction with the interaction
			if(XMLSpinSystem->orientation[j]->interactionRow->id==XMLSpinSystem->interaction[i]->id) 
			{
				//Check if interaction is written in dcm form and save it in a matrix
				if(XMLSpinSystem->orientation[j]->GetdcmRows()->Length>0)
				{
					dcm[0]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->xx;
					dcm[1]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->xy;
					dcm[2]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->xz;
					dcm[3]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->yx;
					dcm[4]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->yy;
					dcm[5]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->yz;
					dcm[6]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->zx;
					dcm[7]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->zy;
					dcm[8]=XMLSpinSystem->orientation[j]->GetdcmRows()[0]->zz;	
				}//Check if interaction is written in euler angles form and save it in a calculated dcm matrix
				else if(XMLSpinSystem->orientation[j]->Geteuler_anglesRows()->Length>0)
				{
					//Read angles
					double alpha, beta, gamma;
					alpha=XMLSpinSystem->orientation[j]->Geteuler_anglesRows()[0]->alpha*PI/180.0f;
					beta=XMLSpinSystem->orientation[j]->Geteuler_anglesRows()[0]->beta*PI/180.0f;
					gamma=XMLSpinSystem->orientation[j]->Geteuler_anglesRows()[0]->gamma*PI/180.0f;

					//Make the transformation to dcm
					SpinachGUI::Orientation^  nOrient;
					nOrient= gcnew SpinachGUI::Orientation(gcnew SpinachGUI::EulerAngles(alpha,beta, gamma));
					SpinachGUI::Matrix3x3^ dc=nOrient->GetAsDCM();

					//Save to dcm matrix
					dcm[0]=dc->xx;dcm[1]=dc->xy;dcm[2]=dc->xz;dcm[3]=dc->yx;
					dcm[4]=dc->yy;dcm[5]=dc->yz;dcm[6]=dc->zx;dcm[7]=dc->zy;dcm[8]=dc->zz;

				}//Check if interaction is written in angle axis form and save it in a calculated dcm matrix
				else if(XMLSpinSystem->orientation[j]->Getangle_axisRows()->Length>0)
				{
					//Read angles
					double ax,ay,az,angle;
					ax=XMLSpinSystem->orientation[j]->Getangle_axisRows()[0]->GetaxisRows()[0]->x;
					ay=XMLSpinSystem->orientation[j]->Getangle_axisRows()[0]->GetaxisRows()[0]->y;
					az=XMLSpinSystem->orientation[j]->Getangle_axisRows()[0]->GetaxisRows()[0]->z;
					angle=XMLSpinSystem->orientation[j]->Getangle_axisRows()[0]->angle*PI/180.0f;

					//Make the transformation to dcm
					SpinachGUI::Orientation^  nOrient;
					nOrient= gcnew SpinachGUI::Orientation(gcnew SpinachGUI::AngleAxis(ax,ay,az,angle));
					SpinachGUI::Matrix3x3^ dc=nOrient->GetAsDCM();

					//Save to dcm matrix
					dcm[0]=dc->xx;dcm[1]=dc->xy;dcm[2]=dc->xz;dcm[3]=dc->yx;
					dcm[4]=dc->yy;dcm[5]=dc->yz;dcm[6]=dc->zx;dcm[7]=dc->zy;dcm[8]=dc->zz;

				}//Check if interaction is written in quaternion form and save it in a calculated dcm matrix
				else if(XMLSpinSystem->orientation[j]->GetquaternionRows()->Length>0)
				{
					//Read parameters
					double re,ii,ij,ik;
					re=XMLSpinSystem->orientation[j]->GetquaternionRows()[0]->re;
					ii=XMLSpinSystem->orientation[j]->GetquaternionRows()[0]->i;
					ij=XMLSpinSystem->orientation[j]->GetquaternionRows()[0]->j;
					ik=XMLSpinSystem->orientation[j]->GetquaternionRows()[0]->k;

					//Make the transformation to dcm
					SpinachGUI::Orientation^  nOrient;
					nOrient=gcnew SpinachGUI::Orientation(gcnew SpinachGUI::Quaternion(re,ii,ij,ik));
					SpinachGUI::Matrix3x3^ dc=nOrient->GetAsDCM();

					//Save to dcm matrix
					dcm[0]=dc->xx;dcm[1]=dc->xy;dcm[2]=dc->xz;dcm[3]=dc->yx;
					dcm[4]=dc->yy;dcm[5]=dc->yz;dcm[6]=dc->zx;dcm[7]=dc->zy;dcm[8]=dc->zz;
				};

				Matrix3d result,eigenVectors,eigenVal;

				//Translate matrixes
				for(int j=0;j<9;j++) 
				{
					eigenVectors(j)=dcm[j];
					eigenVal(j)=0.0;
				};
				eigenVal(0)=eigenvalues[0];eigenVal(4)=eigenvalues[1];eigenVal(8)=eigenvalues[2];

				//Calculating tensor from dcm and eigenvalues
				result= (eigenVectors*eigenVal)*eigenVectors.transpose();
				for(int j=0;j<9;j++) matrix3x3[j]=result(j);
			};
		};

		//Try to create this interaction
		Tensor^ nInteraction;
		try{
			nInteraction=gcnew Tensor(A, B, IntKind, matrix3x3);

			//Check if there is interaction label
			if(!XMLSpinSystem->interaction[i]->IslabelNull()) 
				nInteraction->Label=XMLSpinSystem->interaction[i]->label;

			//Check if there is reference substance
			if(!XMLSpinSystem->interaction[i]->IsreferenceNull()) 
				nInteraction->reference=XMLSpinSystem->interaction[i]->reference;

			//Search Units, else set to unknown
			if (XMLSpinSystem->interaction[i]->units=="Unitless" ) nInteraction->unit=Units::Unitless;
			else if (XMLSpinSystem->interaction[i]->units=="Joule" ) nInteraction->unit=Units::Joule;
			else if (XMLSpinSystem->interaction[i]->units=="Hz" ) nInteraction->unit=Units::Hz;
			else if (XMLSpinSystem->interaction[i]->units=="KHz" ) nInteraction->unit=Units::KHz;
			else if (XMLSpinSystem->interaction[i]->units== "MHz" ) nInteraction->unit=Units::MHz;
			else if (XMLSpinSystem->interaction[i]->units=="eV" ) nInteraction->unit=Units::eV;
			else if (XMLSpinSystem->interaction[i]->units=="Gauss" ) nInteraction->unit=Units::Gauss;
			else if (XMLSpinSystem->interaction[i]->units=="ppm" ) nInteraction->unit=Units::ppm;
			else if (XMLSpinSystem->interaction[i]->units=="Bohr magneton" ) nInteraction->unit=Units::Mi_b;
			else if (XMLSpinSystem->interaction[i]->units=="cm^-1" ) nInteraction->unit=Units::rev_cm;
			else  nInteraction->unit=Units::Unknown;

			//Set the ref. frame
			nInteraction->Frame=refFrame;
		}
		catch(String ^ e)  { throw gcnew Exception("Problem in Reading XML, creating interaction: "+e);};

		//Add to the interaction collection
		InteractionCollection->Add(nInteraction);
	};

	return true;
}

/**
* Main function for opening and writing file using the auto-generated spinxml schema file
* @param model The model from where the data will be exported.
*/
void SpinXML::WriteFile(Model^% model)
{
 SystemModel=model;
 String^ XMLisotope;
 int current=0;

 //Initializing the serializer using the spinxml schemas
 XmlSerializer^ serializer = gcnew XmlSerializer(spin_system::typeid);
 spin_system^ XMLSpinSystem=gcnew spin_system();
 spin_system_ref^ XMLSpinSystemRef=gcnew spin_system_ref();
 XMLSpinSystem->InitVars();
 XMLSpinSystemRef->InitVars();

 //Loop over all atoms to export of atoms and coordinates
 for each (int i in AtomCollection->Keys)
 {
	 spin_system::spinRow^  spinrow;
	 //Create isotope string from the element and the mass number
	 XMLisotope=System::Convert::ToString(((Atom^)AtomCollection[i])->isotope->Mass)+
		 ((Atom^)AtomCollection[i])->isotope->Element;
	 //Add isotope to the serializer
	 spinrow=XMLSpinSystem->spin->AddspinRow(((Atom^)AtomCollection[i])->ID,
		 XMLisotope,
		 ((Atom^)AtomCollection[i])->Label);
	 //Add label if exist to serializer
	 if(((Atom^)AtomCollection[i])->Label==nullptr) 
		 XMLSpinSystem->spin[i-1]->SetlabelNull();

	 //Add coordinates to serializer
	 spin_system::coordinatesRow^  coordinates;
	 coordinates=XMLSpinSystem->coordinates->AddcoordinatesRow(To_Double(((Atom^)AtomCollection[i])->X),
		 To_Double(((Atom^)AtomCollection[i])->Y),
		 To_Double(((Atom^)AtomCollection[i])->Z),
		 spinrow);
 }

 //Loop over all interactions to export of interactions
 for each (int i in InteractionCollection->Keys)
	{//Every interaction except bonds
	if(((Interaction^)InteractionCollection[i])->IntKind!=InteractionKind::CBond)
		{
			spin_system::interactionRow^  interrow;
			Tensor^ interact=(Tensor^)InteractionCollection[i];
			int B_ID;
			String^ label;
			String^ reference;

			//Check if label exist else set as label
			if(((Interaction^)InteractionCollection[i])->Label==nullptr) label="label";
			else label=((Interaction^)InteractionCollection[i])->Label;

			//Check if B atom exist else set as -1
			if(((Interaction^)InteractionCollection[i])->B==nullptr) {B_ID=-1;}
			else B_ID=((Interaction^)InteractionCollection[i])->B->ID;

			//check if reference element exist else set to ref
			if(((Interaction^)InteractionCollection[i])->reference==nullptr) {reference="ref";}
			else reference=((Interaction^)InteractionCollection[i])->reference;

			//Constructor of interaction 
			interrow=XMLSpinSystem->interaction->AddinteractionRow(
				((Interaction^)InteractionCollection[i])->IntKind.ToString()->ToLower(),
				((Interaction^)InteractionCollection[i])->ID,
				((Interaction^)InteractionCollection[i])->unit->get_name(),
				((Interaction^)InteractionCollection[i])->A->ID,
				B_ID,
				((Tensor^)InteractionCollection[i])->Frame->getID(),
				label,
				reference,
				NULL); //Everything will in Tensor form.

			//Set the fields that are missing null
			if(((Interaction^)InteractionCollection[i])->B==nullptr) 
				XMLSpinSystem->interaction[current]->Setspin_bNull();

			if(((Interaction^)InteractionCollection[i])->Label==nullptr) 
				XMLSpinSystem->interaction[current]->SetlabelNull();

			if(((Interaction^)InteractionCollection[i])->reference==nullptr) 
				XMLSpinSystem->interaction[current]->SetreferenceNull();

			//Always interaction will not be scalar
			XMLSpinSystem->interaction[current]->SetscalarNull();

			//Set interaction as  tensor always
			spin_system::tensorRow^  tensrow;
			tensrow=XMLSpinSystem->tensor->AddtensorRow(To_Double(interact->matrix3x3[0]),
				To_Double(interact->matrix3x3[1]),
				To_Double(interact->matrix3x3[2]),
				To_Double(interact->matrix3x3[3]),
				To_Double(interact->matrix3x3[4]),
				To_Double(interact->matrix3x3[5]),
				To_Double(interact->matrix3x3[6]),
				To_Double(interact->matrix3x3[7]),
				To_Double(interact->matrix3x3[8]),
				XMLSpinSystem->interaction[current]);

			//increase Interaction ID
			current++;
	};
 };

 current=0;

 //Loop over all ref. frames to export of reference frame
 for each (int i in SystemModel->RefFrameCollection->Keys)
 {
	 spin_system_ref::reference_frameRow ^ refFrame;
	 ReferenceFrame^ frame=SystemModel->RefFrameCollection[i];
	 String^ label;
	 int parent;

	 //Check if label exist else set as label
	 if(((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->Label==nullptr) label="label";
	 else label=((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->Label;

	 //Check if parent frame exist else set as 0(root)
	 if(((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->ParentRefFrame==nullptr) parent=0;
	 else parent=((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->ParentRefFrame->getID();

	 //Set the ref. frame in the serializer
	 refFrame=
		 XMLSpinSystemRef->reference_frame->Addreference_frameRow(
		 SystemModel->RefFrameCollection[i]->getID(), parent, label);
	 spin_system_ref::directionRow ^ direction=XMLSpinSystemRef->direction->AdddirectionRow(refFrame);

	 //Set the fields that are missing null
	 if(((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->Label==nullptr) 
		 XMLSpinSystemRef->reference_frame[current]->SetlabelNull();
	 if(((ReferenceFrame^ )SystemModel->RefFrameCollection[i])->ParentRefFrame==nullptr) 
		 XMLSpinSystemRef->reference_frame[current]->Setparent_reference_frame_idNull();

	 //Set the direction of ref. frame from the rotation matrix
	 spin_system_ref::dcmRow^ dcmrow;
	 dcmrow=XMLSpinSystemRef->dcm->AdddcmRow(To_Double(frame->rotation[0]),
		 To_Double(frame->rotation[1]),
		 To_Double(frame->rotation[2]),
		 To_Double(frame->rotation[3]),
		 To_Double(frame->rotation[4]),
		 To_Double(frame->rotation[5]),
		 To_Double(frame->rotation[6]),
		 To_Double(frame->rotation[7]),
		 To_Double(frame->rotation[8]),
		 XMLSpinSystemRef->direction[current]);

	 //increase Interaction ID
	 current++;
 };


   //Some Settings for the xml format
   XmlWriterSettings^ settings=gcnew XmlWriterSettings();
   settings->Indent=true;
   settings->ConformanceLevel=Xml::ConformanceLevel::Fragment;
   XmlWriter^ writer = XmlWriter::Create( WritingFile, settings);

   //Export both schemas to xml and close files
   XMLSpinSystem->WriteXml(writer); 
   XMLSpinSystemRef->WriteXml(writer); 
   writer->Close();
   WritingFile->Close();

   //Reopen the file to join properly the two schemas, reading it as normat text
   //not perfect
   StreamReader^ tempFile = gcnew StreamReader(FileName);
   String ^ temp="";
   String ^ final="<?xml version=\"1.0\" encoding=\"utf-8\"?>"+"\r\n";

   //Read the file line by line until the end
   while(!tempFile->EndOfStream)
   {
	   //Read the line
	   temp=tempFile->ReadLine();

	   //If not containing the end of the first schema or the begining of the second schema
	   //(will not copy this line)
	   if(!temp->Contains("</spin_system>") && !temp->Contains("<spin_system_ref>"))
	   {
		   //Replave the name of the second at the end, with the name of the first
		   if(temp->Contains("</spin_system_ref>")) temp="</spin_system>";

		   //Add the line to the final string
		   final+=temp+"\r\n";
	   };
   };

  //Close the file
  tempFile->Close();

  //Reopen the file and clean it
  WritingFile =gcnew StreamWriter(FileName);
  WritingFile->Flush();

  //Write the final string and close it
  WritingFile->Write(final);
  WritingFile->Close();
}
