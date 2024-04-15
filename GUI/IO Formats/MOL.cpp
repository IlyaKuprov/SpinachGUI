#include "../StdAfx.h"
#include "MOL.h"


//Definitions
#define AtomCollection  SystemModel->AtomCollection


/**
*\file MOL.cpp
*/

/**
* @brief Constructor of MOL format
* @param filename Name of the file to be read.
* @param model The model where the imported data will be saved.
*/
MOL::MOL(System::String^ filename, Model^% model)
{
	SystemModel=model;
	FileName=filename;
	ReadingFile = gcnew StreamReader(filename);
	FormatName="MOL";
}

/**
* @brief Main function for opening and reading file
* @return Returns false if the format does not seem to be correct.
*/
bool MOL::LoadFile(void)
{
	bool  OK = true;

	//Turn off Refreshing for faster importing
	AtomCollection->Refreshing=false;

	
	//Read the file until the end of it and as long flag OK is true
	while (!ReadingFile->EndOfStream  && OK )
	{
		int number;							//number of fields in each line
		int totalAtoms=0;					//total number of atoms in the system
		int totalBonds=0;					//total number of bonds in the system
		String^ fileline=gcnew String("");  //line
		array<String^>^numbers = nullptr;   // Matrix of the fields after splitting of a line
		String^ delimStr = " ,";            //seperator of fields
		array<Char>^delimiter = delimStr->ToCharArray(); //Conversion to char array
		int dummy;							// dummy variable used for calling extract function

		try {
			//Read comments 3 lines
			fileline=ReadLine();
			fileline=ReadLine();
			fileline=ReadLine();

			//Read number of atoms and Bonds
			fileline=ReadLine();
			numbers=fileline->Split(delimiter,StringSplitOptions::RemoveEmptyEntries );
			if (!Int32::TryParse(numbers[0], totalAtoms )) OK=false;
			if (!Int32::TryParse(numbers[1], totalBonds )) OK=false;
		}
		catch(Exception ^ e)
		{
			throw gcnew Exception("Unexpected end of file in Line "+LineCount+":"+e->Message) ;
		};

		
		//Read the atom format: 0.4865   -0.1848    1.3191 C 0 0 0 0 0 0 0 0 0 0 0 0              //
		for(int i=0;i<totalAtoms;i++)
		{
			//Try to read a line from the file
			try {fileline=ReadLine();}
			catch(Exception ^ e)
			{
				throw gcnew Exception("Unexpected end of file in Line "+LineCount+":"+e->Message);
			};

			//Number of Fields: 16, Isotope index: 3, XYZ index: 0,1,2
			ExtractIsotopeAndCoordinates(fileline, FormatName, false, dummy, 16, 3, 0, 1, 2, 1.0, AtomCollection);
		};

	   //Read the bond format: 2  1  1  0  0  0  0          //
		number=7;
		for(int i=0;i<totalBonds;i++)
		{
			fileline=ReadLine();
			//Split the line to a number of fields
			numbers=fileline->Split(delimiter,StringSplitOptions::RemoveEmptyEntries );
			if(number=numbers->Length) 
			{ /* Ignore bond data as we create them automatically
				try {
					Interaction^ nInter=gcnew Atom();
					if (!Double::TryParse(numbers[0], nAtom->X ) || !Double::TryParse(numbers[1], nAtom->Y ) ||
						!Double::TryParse(numbers[2], nAtom->Z )) throw gcnew String("Error in Atom coordinates");
					nAtom->isotope=Isotopes::FindIsotope(numbers[3],0, 0);
					nAtom->ID=AtomID;
					InteractionCollection->Add(nAtom);
					AtomID++;
				}
				catch(String ^ e)
				{	
					MessageBox::Show("Problem in Reading MOL format:"+e, "Error", 
						MessageBoxButtons::OK, MessageBoxIcon::Error) ;
					return false;
				}
				*/
			}
			else
			{
				//Wrong number of fields read
				throw gcnew Exception("Problem in Reading Bonds in Line "+LineCount+".") ;
			};
			
		};
		fileline=ReadLine();// M End

	}

	//Turn on again Refreshing which causes calculation of bonds
	AtomCollection->Refreshing=true;
	ReadingFile->Close();
	return OK;

}

