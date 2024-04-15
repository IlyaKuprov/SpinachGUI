#include "../StdAfx.h"
#include "GAMESS.h"

//Definitions
#define AtomCollection  SystemModel->AtomCollection
//Definitions of keywords-phrases found in this format
#define CMD_CARTCOORD             "***** EQUILIBRIUM GEOMETRY LOCATED *****"


/**
*\file GAMESS.cpp
*/

/**
* @brief Constructor of GAMESS format 
* @param filename Name of the file to be read.
* @param model The model where the imported data will be saved.
*/
GAMESS::GAMESS(System::String^ filename, Model^% model)
{
	SystemModel=model;
	FileName=filename;
	ReadingFile = gcnew StreamReader(filename);
    FormatName="GAMESS";

}

/**
* @brief Main function for opening and reading file
* @return Returns false if the format does not seem to be correct.
*/
bool GAMESS::LoadFile(void)
{
	String^ Command=gcnew String("");
	bool  OK = true;

	//Turn off Refreshing for faster importing
	AtomCollection->Refreshing=false;


	//Initializing flags to false, meaning that no any frame was yet read
	read_onceOR=false;


	//Read the file until the end of it and as long flag OK is true
	while (!ReadingFile->EndOfStream  && OK )
	{

		Command= ReadLine() ;

		//Reading different sections of the file according to keywords-phrases
		if(OK)
		{
			//Read coordinates
			if(Command->Contains(CMD_CARTCOORD))
			{  
				OK=read_CARTCOORD();
				read_onceOR=true; //read at least once
			}
		};

		//Wrong format inside senctions
		if(!OK)  throw gcnew Exception("Problem in Reading File in Line "+LineCount+".") ;
	};

	// Check if file is a valid GAMESS format, having at least one of the sections
	if(!(read_onceOR )) return false;

	//Turn on again Refreshing which causes calculation of bonds
	AtomCollection->Refreshing=true;
	ReadingFile->Close();
	return true;
}

/**
* @brief Main function for reading coordinates from the file
* @return Returns false if the format does not seem to be correct.
*/
bool GAMESS::read_CARTCOORD()
{
	String^ fileline=gcnew String("");  //line
	int AtomID=1;						//Saving the atom ID

	//Readin initial dummy lines
	fileline=ReadLine() ; 
	//COORDINATES OF ALL ATOMS ARE (ANGS)
	fileline=ReadLine() ; 
	//ATOM   CHARGE       X              Y              Z
	fileline=ReadLine() ; 
	//------------------------------------------------------------


	fileline="";

	while ((fileline=ReadLine())->Length>2 )
	{
		//Number of Fields: 5, Isotope index: 0, XYZ index: 2,3,4
		ExtractIsotopeAndCoordinates(fileline, FormatName, read_onceOR, AtomID,
			5, 0, 2, 3, 4, 1.0, AtomCollection);
	};

	return true;

}


