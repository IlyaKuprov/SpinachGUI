#include "../StdAfx.h"
#include "Model.h"

/**
*\file Model.cpp
*/

#pragma region "Referenceframe, Tensor and Interaction"

/**
* @brief Constructor of Reference frame.
*/
ReferenceFrame::ReferenceFrame()	 
{ 
	//Set the rotation matrix as ID
	Matrix3x3 ^Matrix=gcnew Matrix3x3();
	Matrix[0]=1.0; Matrix[4]=1.0; Matrix[8]=1.0;
	Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
	Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
	rotation=Matrix;

	//Fire an change event
	OnPropertyChanged(gcnew PropertyChangedEventArgs("Rotation"));

	//Connect the event with the event handler for the rotation matrix
	rotation->PropertyChanged+=
		gcnew System::ComponentModel::PropertyChangedEventHandler(this,&ReferenceFrame::RotationChange);

};

/**
* @brief Constructor of Reference frame using rotation matrix.
* @param  anotherMatrix3x3 The rotation matrix of the tensor.
*/
ReferenceFrame::ReferenceFrame(Matrix3x3^ anotherMatrix3x3)	
{ 
	//Set the rotation matrix
	rotation=anotherMatrix3x3;

	//Fire an change event
	OnPropertyChanged(gcnew PropertyChangedEventArgs("Rotation"));

	//Connect the event with the event handler for the rotation matrix
	rotation->PropertyChanged+=
		gcnew System::ComponentModel::PropertyChangedEventHandler(this,&ReferenceFrame::RotationChange);
};

/**
* @brief Constructor of Tensor inherited by interaction using basic properties.
* @param A Atom A of interaction.
* @param B Atom B of interaction.
* @param Kind Kind of the interaction.
* @param  anotherMatrix3x3 The rotation matrix of the tensor.
*/
Tensor::Tensor(Atom^ A, Atom^ B, InteractionKind Kind, ::Matrix3x3^ anotherMatrix3x3):Interaction(A,B,Kind)
{ 
	//Always Symmetrize-Make Diagonal
	aMatrix3x3=gcnew ::Matrix3x3();
	aMatrix3x3[0]=anotherMatrix3x3[0];
	aMatrix3x3[4]=anotherMatrix3x3[4];
	aMatrix3x3[8]=anotherMatrix3x3[8];
	aMatrix3x3[1]=(anotherMatrix3x3[1]+anotherMatrix3x3[3])/2.0f;
	aMatrix3x3[3]=aMatrix3x3[1];
	aMatrix3x3[2]=(anotherMatrix3x3[2]+anotherMatrix3x3[6])/2.0f;
	aMatrix3x3[6]=aMatrix3x3[2];
	aMatrix3x3[5]=(anotherMatrix3x3[5]+anotherMatrix3x3[7])/2.0f;
	aMatrix3x3[7]=aMatrix3x3[5];

	//Calculate the eigenvalues and eigenvectors of the interaction
	Calculate_EigenStates();

	//Fire an change event
	OnPropertyChanged(gcnew PropertyChangedEventArgs("Matrix3x3"));

	//Connect the event with the event handler for the matrix
	aMatrix3x3->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(this,&Tensor::TensorChange);
};

/**
* @brief Function for calculating the eigenvalues and 
* eigenvectors of the interaction. Eigenvectors are calculated to the root frame.
*/
System::Void Tensor::Calculate_EigenStates()
{
	//Pass matrix to the eigen library
	Matrix3d A;
	A<<aMatrix3x3[0],aMatrix3x3[1],aMatrix3x3[2],
		aMatrix3x3[3],aMatrix3x3[4],aMatrix3x3[5],
		aMatrix3x3[6],aMatrix3x3[7],aMatrix3x3[8];

	//Solve the eigenvalue problem
	SelfAdjointEigenSolver<Matrix3d> eigensolver(A);
	if (eigensolver.info() != Success) abort();

	//Pass it back to the eigen value matrix
	eigen[0]=eigensolver.eigenvalues()[0];
	eigen[1]=eigensolver.eigenvalues()[1];
	eigen[2]=eigensolver.eigenvalues()[2];

	Matrix3d refFrame,result;
	result=eigensolver.eigenvectors();

	//Loop over all parent ref frames, in order to multiply them with the matrix
	for(ReferenceFrame^ next=frame;next!=nullptr;next=next->ParentRefFrame)
	{
		//Pass ref frame matrix to the eigen library
		refFrame<<next->matrix3x3[0],next->matrix3x3[1],next->matrix3x3[2],
			next->matrix3x3[3],next->matrix3x3[4],next->matrix3x3[5],
			next->matrix3x3[6],next->matrix3x3[7],next->matrix3x3[8];

		//Multiply the matrix with the eigenvector matric (dcm)
		result=refFrame*result;
	}

	//Pass it back to the eigen vector matrix
	for(int i=0;i<9;i++) dcm[i]=result(i);
	//Or this
	/*
	dcm[0]=result(0); dcm[1]=result(3); dcm[2]=result(6);
	dcm[3]=result(1); dcm[4]=result(4); dcm[5]=result(7);
	dcm[6]=result(2); dcm[7]=result(5);	dcm[8]=result(8);
	*/
}

/**
* @brief Constructor of Interaction using basic properties.
* @param a Atom A of interaction.
* @param b Atom B of interaction.
* @param kind Kind of the interaction.
*/
Interaction::Interaction(Atom^% a, Atom^% b, InteractionKind kind)
{
	//Try to create valid interaction else throw message
	try{
		//Checks if the attempted creation of interaction is valid
		ValidCreationChange(a, b, kind, "create ");

		//Make 3x1 Matrix with 0 eigen values
		aeigen= gcnew ObservableCollection<double>();
		aeigen->Add(0.0f);aeigen->Add(0.0f);aeigen->Add(0.0f);

		//Make 9x1 Matrix with eigenvectors to 0
		adcm= gcnew ObservableCollection<double>();
		for (int i=0;i<9;i++) adcm->Add(0.0f);
		//Set atom A, B, kind of interaction
		A=a;B=b;
		IntKind=kind;

		//Connect the events with the event handlers
		aeigen->CollectionChanged+=gcnew System::Collections::Specialized::NotifyCollectionChangedEventHandler(this,&Interaction::InteractionChange);
		adcm->CollectionChanged+=gcnew System::Collections::Specialized::NotifyCollectionChangedEventHandler(this,&Interaction::InteractionChange);	  
	}
	catch(String^ e){throw e;};
};

/**
* @brief Function that checks if the attempted interaction is valid.
* @param tA Atom A of interaction.
* @param tB Atom B of interaction.
* @param aIntKind Kind of the interaction.
* @param function Function that is attempted, a string usually create or change.
*/
System::Void Interaction::ValidCreationChange(Atom^ tA, Atom ^tB, InteractionKind aIntKind, String ^ function)
{
//Quadropolar and  are valid for isotopes only 
if(aIntKind==InteractionKind::Quadrupolar && !(tA->isotope->Spin!=0.5 &&  	
	tA->isotope->Element!="e" && tB->isotope->Element!="e" && tA==tB))  	
	throw gcnew System::String("Cannot "+function+"this interaction: Valid only for spin>0.5 and no electrons."); 	
//Chemical shielding and Shift are valid for isotopes only 
else if((aIntKind==InteractionKind::CShielding || aIntKind==InteractionKind::Shift ) &&    
		!(tA->isotope->Element!="e" && tB->isotope->Element!="e" && tA==tB)) 
  		throw gcnew System::String("Cannot "+function+"this interaction: Valid only for no electrons."); 	
//Zerofield tensor, Gtensor and CHItensors are valid on electrons only 
else if((aIntKind==InteractionKind::ZFS || aIntKind==InteractionKind::GTensor) &&  
		!(tA->isotope->Element=="e" && tB->isotope->Element=="e" && tA==tB)) 
		throw gcnew System::String("Cannot "+function+"this interaction: Valid only for electrons."); 
//CHItensor are valid on chi electrons only 
else if((aIntKind==InteractionKind::CHITensor) &&  
		!(tA->isotope->Element=="chi" && tB->isotope->Element=="chi" && tA==tB)) 
		throw gcnew System::String("Cannot "+function+"this interaction: Valid only for electrons."); 
//Hyperfine is valid when isotope coupled to electron 
else if(aIntKind==InteractionKind::HFC &&  !(tA->isotope->Element!="e" && tB->isotope->Element=="e" && tA!=tB)) 
	throw gcnew System::String("Cannot "+function+"this interaction: Must couple isotope with electron.");  	
//For changing Exhange we need two different electrons 
else if(aIntKind==InteractionKind::Exchange &&  !(tA->isotope->Element=="e" && tB->isotope->Element=="e" && tA!=tB)) 
	throw gcnew System::String("Cannot "+function+"this interaction: Must couple two different electrons.");   
//For changing to Jcoupling we need two different elements, no electrons 
else if(aIntKind==InteractionKind::Jcoupling &&  !(tA->isotope->Element!="e" && tB->isotope->Element!="e" && tA!=tB)) 
	throw gcnew System::String("Cannot "+function+" Jcoupling: Must couple two different elements, no electrons."); 

};

#pragma endregion

#pragma region AtomsDictionary

System::Void AtomsDictionary::Clear()
{
	newID=1;
	electron_number=0;		
	electron_chi_number=0;
	aDictionary->Clear();
	MinX=MinY=MinZ=dMax;
	MaxX=MaxY=MaxZ=-dMax;
};

AtomsDictionary::AtomsDictionary(InteractionsDictionary ^%aInteractions)
{
	aDictionary=gcnew Dictionary <int, Atom^>();
	newID=1;
	electron_number=0;
	electron_chi_number=0;
	Interactions=aInteractions;
	//Synchronize AtomsDictionary_electron_number
	//pin_ptr<int> temp= &electron_number;
	//Interactions->AtomsDictionary_electron_number=temp;
	//Initialization of Minimum and maximum
	MinX=MinY=MinZ=dMax;
	MaxX=MaxY=MaxZ=-dMax;
	refresh=true;
};

System::Void AtomsDictionary::Add(Atom^ atom)
{
	//Add atom in the end of Dictionary
	atom->ID=newID;
	aDictionary->Add(newID,atom); 
	//Check if new atom electron, then increase number of electrons
	if(atom->isotope->Element=="e") electron_number++;
	if(atom->isotope->Element=="chi") electron_chi_number++;

	//Add bonds for the new atom which was added at the end
	Atom^ A=atom;
	for(int i=1;i<aDictionary->Count;i++) 
	{
		Atom^ B=(Atom^)aDictionary[i];
		if (A->isotope->Element!="e" && B->isotope->Element!="e")
		{
			double distance=sqrt((A->X-B->X)*(A->X-B->X)+(A->Y-B->Y)*(A->Y-B->Y)+(A->Z-B->Z)*(A->Z-B->Z));
			::Matrix3x3 ^Matrix=gcnew ::Matrix3x3();
			Matrix[0]=distance; Matrix[4]=distance; Matrix[8]=distance;
			Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
			Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
			Tensor^ nInteraction=gcnew Tensor(A,B,InteractionKind::CBond,Matrix);
			Interactions->Add(nInteraction);
		};
	};

	//Check if Atom is maximum or minimum and save ID
	if(atom->isotope->Element!="e")
	{
		if(atom->X < MinX) {MinX=atom->X; iMinX=atom->ID;}
		if(atom->X > MaxX) {MaxX=atom->X; iMaxX=atom->ID;}
		if(atom->Y < MinY) {MinY=atom->Y; iMinY=atom->ID;}
		if(atom->Y > MaxY) {MaxY=atom->Y; iMaxY=atom->ID;}
		if(atom->Z < MinZ) {MinZ=atom->Z; iMinZ=atom->ID;}
		if(atom->Z > MaxZ) {MaxZ=atom->Z; iMaxZ=atom->ID;}
	};

	//Add event handler to atom	
	//tempAtom=atom;
	atom->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(
		this,&AtomsDictionary::AtomsDictionaryChange);

	//Event Handler
	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Add, 
		gcnew KeyValuePair<int, Atom^>(newID, atom)));
	//Increase new ID number
	newID++;

}

System::Void AtomsDictionary::RemoveAt(int aID)
{
	//Check existance with a simple test
	try	{int test=((Atom ^)aDictionary[aID])->getID();}
	catch(KeyNotFoundException^){throw gcnew System::String("Atom with ID "+aID+" does not exist.");};
	//Check if electron then reduce number of electrons
	if(((Atom ^)aDictionary[aID])->isotope->Element=="e") electron_number--;	
	if(((Atom ^)aDictionary[aID])->isotope->Element=="chi") electron_chi_number--;

	//Remove interactions with this atom

	InteractionsDictionary ^newInteractionDic=gcnew InteractionsDictionary();
	for each(int i in  Interactions->Keys)
	{
		if(((Interaction^)Interactions[i])->B==nullptr)
		{
			if(((Interaction^)Interactions[i])->A->ID!=aID) 
				newInteractionDic->Add((Interaction ^)Interactions[i]);	
		}
		else if(((Interaction^)Interactions[i])->B->ID!=aID && 
			((Interaction^)Interactions[i])->A->ID!=aID) 
			newInteractionDic->Add((Interaction ^)Interactions[i]);
	};
	Interactions->Clear();
	for each(int i in  newInteractionDic->Keys) Interactions->Add(newInteractionDic[i]);

	//Event Handler
	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
		gcnew KeyValuePair<int, Atom^>(aID, ((Atom ^)this[aID]))));

	//Move eveything one place before ovewriting the desired deleted element
	for(int i=aID;i<aDictionary->Count;i++) {aDictionary[i]=aDictionary[i+1];((Atom ^)aDictionary[i])->ID=i;}
	//Remove the last element-duplicate as pre-last 
	aDictionary->Remove(--newID);


	//If the to-be-removed element is minimum or maximum, search for new minimum or maximum
	//Minimums
	if(aID==iMinX)
	{
		MinX=dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MinX>aDictionary[i]->X) {MinX=aDictionary[i]->X;iMinX=i;}
	};
	if(aID==iMinY)
	{
		MinY=dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MinY>aDictionary[i]->Y) {MinY=aDictionary[i]->Y;iMinY=i;}
	};
	if(aID==iMinZ)
	{
		MinZ=dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MinZ>aDictionary[i]->Z) {MinZ=aDictionary[i]->Z;iMinZ=i;}
	};
	//Maximums
	if(aID==iMaxX)
	{
		MaxX=-dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MaxX<aDictionary[i]->X) {MaxX=aDictionary[i]->X;iMaxX=i;}
	};
	if(aID==iMaxY)
	{
		MaxY=-dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MaxY<aDictionary[i]->Y) {MaxY=aDictionary[i]->Y;iMaxY=i;}
	};
	if(aID==iMaxZ)
	{
		MaxZ=-dMax;
		for each(int i in aDictionary->Keys) if(aID!=i && MaxZ<aDictionary[i]->Z) {MaxZ=aDictionary[i]->Z;iMaxZ=i;}
	};


};

System::Void AtomsDictionary::AtomsDictionaryChange(System::Object ^ sender,
													System::ComponentModel::PropertyChangedEventArgs^ e) 
{
	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
		gcnew KeyValuePair<int, Atom^>(
		((Atom^) sender)->getID(), 
		((Atom^) sender))));

	//Changes in X,Y,Z
	if(refresh && (e->PropertyName->Contains("X") || e->PropertyName->Contains("Y") || e->PropertyName->Contains("Z")))
	{
		//Recalculate bond distances
		for(int i=-1;i>Interactions->bondID;i--)
		{
			Atom^ A=((Interaction^)Interactions[i])->A;
			Atom^ B=((Interaction^)Interactions[i])->B;
			if(A->getID()==((Atom^) sender)->getID() || B->getID()==((Atom^) sender)->getID())
			{
				double distance=sqrt((A->X-B->X)*(A->X-B->X)+(A->Y-B->Y)*(A->Y-B->Y)+(A->Z-B->Z)*(A->Z-B->Z));
				::Matrix3x3 ^Matrix=gcnew ::Matrix3x3();
				Matrix[0]=distance; Matrix[4]=distance; Matrix[8]=distance;
				Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
				Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
				((Tensor^)Interactions[i])->matrix3x3=Matrix;
			};
		};

		//Recalculate maximums and minimums
		if(e->PropertyName->Contains("X"))
		{
			//If any of elements change to larger than current Max, then this is the new Max
			//else if the element which is Max is changed(to smaller) search all for new Max.
			if(((Atom^) sender)->X > MaxX ) {MaxX=((Atom^) sender)->X;iMaxX=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMaxX)
			{
				MaxX=-dMax;
				for each(int i in aDictionary->Keys) if(MaxX<this[i]->X) {MaxX=this[i]->X;iMaxX=i;};
			};			
			//Similarly Min	
			if(((Atom^) sender)->X < MinX ) {MinX=((Atom^) sender)->X;iMinX=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMinX)
			{
				MinX=dMax;
				for each(int i in aDictionary->Keys) if(MinX>this[i]->X) {MinX=this[i]->X;iMinX=i;};
			};
		}
		else if(e->PropertyName->Contains("Y"))
		{
			//If any of elements change to larger than current Max, then this is the new Max
			//else if the element which is Max is changed(to smaller) search all for new Max.
			if(((Atom^) sender)->Y > MaxY ) {MaxY=((Atom^) sender)->Y;iMaxY=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMaxY)
			{
				MaxY=-dMax;
				for each(int i in aDictionary->Keys) if(MaxY<this[i]->Y) {MaxY=this[i]->Y;iMaxY=i;};
			};			
			//Similarly Min	
			if(((Atom^) sender)->Y < MinY ) {MinY=((Atom^) sender)->Y;iMinY=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMinY)
			{
				MinY=dMax;
				for each(int i in aDictionary->Keys) if(MinY>this[i]->Y) {MinY=this[i]->Y;iMinY=i;};
			};
		}
		else if(e->PropertyName->Contains("Z"))
		{
			//If any of elements change to larger than current Max, then this is the new Max
			//else if the element which is Max is changed(to smaller) search all for new Max.
			if(((Atom^) sender)->Z > MaxZ ) {MaxZ=((Atom^) sender)->Z;iMaxZ=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMaxZ)
			{
				MaxZ=-dMax;
				for each(int i in aDictionary->Keys) if(MaxZ<this[i]->Z) {MaxZ=this[i]->Z;iMaxZ=i;};
			};			
			//Similarly Min	
			if(((Atom^) sender)->Z < MinZ ) {MinZ=((Atom^) sender)->Z;iMinZ=((Atom^) sender)->ID;}
			else if(((Atom^) sender)->ID==iMinZ)
			{
				MinZ=dMax;
				for each(int i in aDictionary->Keys) if(MinZ>this[i]->Z) {MinZ=this[i]->Z;iMinZ=i;};
			};
		}; 
	};

	if(e->PropertyName->Contains("Isotope"))
	{
		String ^ isotopeName=e->PropertyName->Substring(e->PropertyName->LastIndexOf("$"))->Replace("$","");
		//New non electron /old electron, decrease number of electrons for g interaction
		if(isotopeName=="e" && ((Atom ^)sender)->isotope->Element!="e") electron_number--;
		//New electron /old non electron, increase number of electrons for g interaction
		if(isotopeName!="e" && ((Atom ^)sender)->isotope->Element=="e") electron_number++;
			
		//New non electron /old electron, decrease number of electrons for chi interaction
		if(isotopeName=="chi" && ((Atom ^)sender)->isotope->Element!="chi") electron_chi_number--;
		//New electron /old non electron, increase number of electrons for chi interaction
		if(isotopeName!="chi" && ((Atom ^)sender)->isotope->Element=="chi") electron_chi_number++;

		//If the isotope change to isotope with spin=0.5 remove quadropolar interactions of it
		if(e->PropertyName->Contains("SpinChange") && ((Atom^) sender)->isotope->Spin==0.5 )
		{
			InteractionsDictionary ^newInteractionDic=gcnew InteractionsDictionary();
			for each(int i in Interactions->Keys)
			{
				if((((Atom^) sender)!=((Interaction^)Interactions[i])->A &&
					((Atom^) sender)!=((Interaction^)Interactions[i])->B) || 
					((Interaction^)Interactions[i])->IntKind!=InteractionKind::Quadrupolar)
					newInteractionDic->Add((Interaction ^)Interactions[i]);
			};
			Interactions->Clear();
			for each(int i in  newInteractionDic->Keys) Interactions->Add(newInteractionDic[i]);
		};

		//Change to non electron
		if(isotopeName=="e" && ((Atom^) sender)->isotope->Element!="e")
		{
			InteractionsDictionary ^newInteractionDic=gcnew InteractionsDictionary();
			for each(int i in Interactions->Keys)
			{
				if(!(
					//Zerofield tensor, Gtensor and CHItensors are valid on electrons only
						(((Atom^) sender)==((Interaction^)Interactions[i])->A ||
						((Atom^) sender)==((Interaction^)Interactions[i])->B) && 
						(((Interaction^)Interactions[i])->IntKind==InteractionKind::ZFS ||
						((Interaction^)Interactions[i])->IntKind==InteractionKind::GTensor ||											
						((Interaction^)Interactions[i])->IntKind==InteractionKind::CHITensor)
						||
						//Hyperfine is valid when isotope coupled to electron
						((Atom^) sender)==((Interaction^)Interactions[i])->B && 
						((Interaction^)Interactions[i])->IntKind==InteractionKind::HFC
						||
						//Exhange we need two different electrons
						(((Atom^) sender)==((Interaction^)Interactions[i])->A ||
						((Atom^) sender)==((Interaction^)Interactions[i])->B) && 
						((Interaction^)Interactions[i])->IntKind==InteractionKind::Exchange)
						)
						newInteractionDic->Add((Interaction ^)Interactions[i]);
			};
			Interactions->Clear();
			for each(int i in  newInteractionDic->Keys) Interactions->Add(newInteractionDic[i]);

			Atom^ A=((Atom^) sender);
			for(int i=1;i<aDictionary->Count;i++) 
			{
				Atom^ B=(Atom^)aDictionary[i];
				if (B->isotope->Element!="e")
				{
					double distance=sqrt((A->X-B->X)*(A->X-B->X)+(A->Y-B->Y)*(A->Y-B->Y)+(A->Z-B->Z)*(A->Z-B->Z));
					::Matrix3x3 ^Matrix=gcnew ::Matrix3x3();
					Matrix[0]=distance; Matrix[4]=distance; Matrix[8]=distance;
					Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
					Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
					Tensor^ nInteraction=gcnew Tensor(A,B,InteractionKind::CBond,Matrix);
					Interactions->Add(nInteraction);
				};
			};

			//Check if Atom is maximum or minimum and save ID
			if(A->X < MinX) {MinX=A->X; iMinX=A->ID;}
			if(A->X > MaxX) {MaxX=A->X; iMaxX=A->ID;}
			if(A->Y < MinY) {MinY=A->Y; iMinY=A->ID;}
			if(A->Y > MaxY) {MaxY=A->Y; iMaxY=A->ID;}
			if(A->Z < MinZ) {MinZ=A->Z; iMinZ=A->ID;}
			if(A->Z > MaxZ) {MaxZ=A->Z; iMaxZ=A->ID;}

		};

		//Change to electron
		if(isotopeName!="e" && ((Atom^) sender)->isotope->Element=="e")
		{

			InteractionsDictionary ^newInteractionDic=gcnew InteractionsDictionary();
			for each(int i in Interactions->Keys)
			{
				if(!(
					//For adding Jcoupling we need two different elements, no electrons
						(((Atom^) sender)==((Interaction^)Interactions[i])->A ||
						((Atom^) sender)==((Interaction^)Interactions[i])->B) && 
						(((Interaction^)Interactions[i])->IntKind==InteractionKind::Jcoupling ||
						((Interaction^)Interactions[i])->IntKind==InteractionKind::CBond)
						||
						//Hyperfine is valid when isotope coupled to electron
						(((Atom^) sender)==((Interaction^)Interactions[i])->A && 
						(((Interaction^)Interactions[i])->IntKind==InteractionKind::HFC||
						((Interaction^)Interactions[i])->IntKind==InteractionKind::CShielding||
						((Interaction^)Interactions[i])->IntKind==InteractionKind::Shift||
						((Interaction^)Interactions[i])->IntKind==InteractionKind::Quadrupolar)))
						)
						newInteractionDic->Add((Interaction ^)Interactions[i]);
			};
			Interactions->Clear();
			for each(int i in  newInteractionDic->Keys) Interactions->Add(newInteractionDic[i]);
		};


	};
};


#pragma endregion

#pragma region InteractionsDictionary

InteractionsDictionary::InteractionsDictionary()
{
	aDictionary=gcnew Dictionary <int, Interaction^>();
	newID=1;bondID=-1;
	InterKindCount=gcnew Dictionary<InteractionKind, int>();
	InterKindMax=gcnew Dictionary<InteractionKind, double>();
	InterKindMin=gcnew Dictionary<InteractionKind, double>();
	iInterKindMax=gcnew Dictionary<InteractionKind, int>();
	iInterKindMin=gcnew Dictionary<InteractionKind, int>() ;
	//Initiate the number, Max and Min of each interaction kind
	for each (InteractionKind IntKind in Enum::GetValues(InteractionKind::typeid))
	{
		InterKindCount->Add(IntKind,0);
		InterKindMax->Add(IntKind,-1*dMax);
		InterKindMin->Add(IntKind,dMax);
		iInterKindMax->Add(IntKind,0);
		iInterKindMin->Add(IntKind,0);
	};
};

System::Void InteractionsDictionary::InteractionsDictionaryChange(System::Object ^ sender,
																  System::ComponentModel::PropertyChangedEventArgs^ e) 
{
	//Changes in interaction kind
	if(e->PropertyName->Contains("InteractionKind"))
	{ 
		//Increase the number of new kind interaction
		InterKindCount[((Interaction^) sender)->IntKind]++;
		UpdateEigenMinMax((Interaction ^)sender, ((Interaction^) sender)->IntKind);
		//Reduce the number of old kind interaction, stored in the property
		InterKindCount[(InteractionKind) Enum::Parse(InteractionKind::typeid, 
			e->PropertyName->Replace("InteractionKind ",""))]--;
		UpdateEigenMinMax((Interaction ^)sender, (InteractionKind) Enum::Parse(InteractionKind::typeid, 
			e->PropertyName->Replace("InteractionKind ","")));
	};
	//Changes in eigen values
	if(e->PropertyName=="eigen") UpdateEigenMinMax((Interaction ^)sender, ((Interaction^) sender)->IntKind);

	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
		gcnew KeyValuePair<int, Interaction^>(
		((Interaction^) sender)->getID(), 
		((Interaction^) sender))));
};


System::Void InteractionsDictionary::UpdateEigenMinMax(Interaction^ aInteraction, InteractionKind intKind)
{
	//If any of elements change to larger than current Max, then this is the new Max
	//else if the element which is Max is changed(to smaller) search all for new Max.
	for(int j=0;j<3;j++)
	{
		//Max
		if(abs(aInteraction->eigen[j]) > InterKindMax[intKind]) 
		{
			InterKindMax[intKind]=abs(aInteraction->eigen[j]);
			iInterKindMax[intKind]=3*aInteraction->ID+j;
		}
		else if(aInteraction->ID==iInterKindMax[intKind]/3 &&
			j==iInterKindMax[intKind]%3)
		{
			InterKindMax[intKind]=-dMax;
			for each(int i in Keys) if(InterKindMax[intKind]<abs(this[i]->eigen[j]) 
				&& this[i]->IntKind==intKind) 
			{
				InterKindMax[intKind]=abs(this[i]->eigen[j]);
				iInterKindMax[intKind]=3*i+j;
			};
		};	
		//Similarly Min	
		if(abs(aInteraction->eigen[j]) < InterKindMin[intKind]) 
		{
			InterKindMin[intKind]=abs(aInteraction->eigen[j]);
			iInterKindMin[intKind]=3*aInteraction->ID+j;
		}
		else if(aInteraction->ID==iInterKindMin[intKind]/3 &&
			j==iInterKindMin[intKind]%3)
		{
			InterKindMin[intKind]=dMax;
			for each(int i in Keys) if(InterKindMin[intKind]>abs(this[i]->eigen[j])
				&& this[i]->IntKind==intKind) 
			{
				InterKindMin[intKind]=abs(this[i]->eigen[j]);
				iInterKindMin[intKind]=3*i+j;
			};


		};
	};
};

System::Void InteractionsDictionary::RemoveAt(int aID) 
{
	//Decrease the number of the specific kind, first
	InterKindCount[aDictionary[aID]->IntKind]--;


	//If the to-be-removed element is minimum or maximum, search for new minimum or maximum
	//Minima

	for(int j=0;j<3;j++) 
		if(abs(abs(aDictionary[aID]->eigen[j])-InterKindMin[aDictionary[aID]->IntKind]) < epsilo)
		{
			InterKindMin[aDictionary[aID]->IntKind]=dMax;
			for each(int i in Keys) if(aID!=i && InterKindMin[aDictionary[aID]->IntKind]>aDictionary[i]->eigen[j]) 
			{InterKindMin[aDictionary[aID]->IntKind]=aDictionary[i]->eigen[j];iInterKindMin[aDictionary[aID]->IntKind]=3*i+j;}
		};
		//Maxima
		for(int j=0;j<3;j++) 
			if(abs(abs(aDictionary[aID]->eigen[j])-InterKindMax[aDictionary[aID]->IntKind]) < epsilo)
			{
				InterKindMax[aDictionary[aID]->IntKind]=-dMax;
				for each(int i in Keys) if(aID!=i && InterKindMax[aDictionary[aID]->IntKind]<aDictionary[i]->eigen[j]) 
				{InterKindMax[aDictionary[aID]->IntKind]=aDictionary[i]->eigen[j];iInterKindMax[aDictionary[aID]->IntKind]=3*i+j;}
			};

			OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
				gcnew KeyValuePair<int, Interaction^>(aID, ((Interaction ^)aDictionary[aID]))));

			if(aID<0) //Bond
			{
				for(int i=aID;i>bondID+1;i--) {aDictionary[i]=aDictionary[i-1];((Interaction ^)aDictionary[i])->ID=i;}
				try	{aDictionary->Remove(++bondID);}
				catch(KeyNotFoundException^){throw gcnew System::String("Interaction with ID "+aID+" does not exist.");};
			}
			else //Other Kinds
			{
				//Move eveything one place before ovewriting the desired deleted interaction
				for(int i=aID;i<newID-1;i++) {aDictionary[i]=aDictionary[i+1];((Interaction ^)aDictionary[i])->ID=i;}
				//Remove the last interaction-duplicate as pre-last 
				try	{aDictionary->Remove(--newID);}
				catch(KeyNotFoundException^){throw gcnew System::String("Interaction with ID "+aID+" does not exist.");};
			}
};
System::Void InteractionsDictionary::Clear()
{
	newID=1;bondID=-1;
	aDictionary->Clear();
	//Initiate the number, Max and Min of each interaction kind
	for each (InteractionKind IntKind in Enum::GetValues(InteractionKind::typeid))
	{
		InterKindCount[IntKind]=0;
		InterKindMax[IntKind]=-1*dMax;
		InterKindMin[IntKind]=dMax;
		iInterKindMax[IntKind]=0;
		iInterKindMin[IntKind]=0;
	};

};
System::Void InteractionsDictionary::Add(Interaction^ inter)
{
	//Check if bond or other kind
	if(inter->IntKind==InteractionKind::CBond)
	{
		inter->ID=bondID;
		aDictionary->Add(bondID,inter); 
		bondID--;
	}
	else 	//Everything else coupling
	{
		inter->ID=newID;
		aDictionary->Add(newID,inter); 
		newID++;

	};

	//For the new Interaction add event handler
	inter->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(
		this,&InteractionsDictionary::InteractionsDictionaryChange);
	//Increase the number of the specific kind
	InterKindCount[inter->IntKind]++;
	//Check if Interaction is minimum and save ID
	for(int j=0;j<3;j++) if(abs(inter->eigen[j]) < InterKindMin[inter->IntKind]) 
	{
		InterKindMin[inter->IntKind]=abs(inter->eigen[j]); 
		iInterKindMin[inter->IntKind]=3*inter->ID+j;
	};
	//Check if Interaction is maximum and save ID
	for(int j=0;j<3;j++) if(abs(inter->eigen[j]) > InterKindMax[inter->IntKind]) 
	{
		InterKindMax[inter->IntKind]=abs(inter->eigen[j]); 
		iInterKindMax[inter->IntKind]=3*inter->ID+j;
	};

	//Event Handler
	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Add, 
		gcnew KeyValuePair<int, Interaction^>(newID, inter)));


};

System::Void InteractionsDictionary::FilterInteractions(InteractionKind^ kind, double threshold, bool znorm )
{
	/*
	InteractionsDictionary ^newInteractionDic=gcnew InteractionsDictionary();
	for each(int i in  Interactions->Keys)
	{
	if(((Interaction^)Interactions[i])->B==nullptr)
	{
	if(((Interaction^)Interactions[i])->A->ID!=aID) 
	newInteractionDic->Add((Interaction ^)Interactions[i]);	
	}
	else if(((Interaction^)Interactions[i])->B->ID!=aID && 
	((Interaction^)Interactions[i])->A->ID!=aID) 
	newInteractionDic->Add((Interaction ^)Interactions[i]);
	};
	Interactions->Clear();
	for each(int i in  newInteractionDic->Keys) Interactions->Add(newInteractionDic[i]);
	*/
}
#pragma endregion

#pragma region ReferenceFramesDictionary
ReferenceFramesDictionary::ReferenceFramesDictionary(InteractionsDictionary ^%aInteractions)
{
	aDictionary=gcnew Dictionary <int, ReferenceFrame^>();
	newID=2;
	Interactions=aInteractions;

	//Create lab-root reference frame
	::Matrix3x3 ^Matrix=gcnew ::Matrix3x3();
	Matrix[0]=1.0; Matrix[4]=1.0; Matrix[8]=1.0;
	Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
	Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
	ReferenceFrame^ frame=gcnew ReferenceFrame(Matrix);
	frame->ID=1;
	frame->ParentRefFrame=nullptr;
	frame->Label="Lab Frame";
	frame->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(
		this,&ReferenceFramesDictionary::ReferenceFramesDictionaryChange);
	aDictionary->Add(1,frame); 


};



System::Void ReferenceFramesDictionary::TransformToFrame(ReferenceFrame^ frame,Tensor ^% inter)
{
	Matrix3d A;
	A<<inter->matrix3x3[0], inter->matrix3x3[1], inter->matrix3x3[2],
		inter->matrix3x3[3], inter->matrix3x3[4], inter->matrix3x3[5],
		inter->matrix3x3[6], inter->matrix3x3[7], inter->matrix3x3[8];


	Matrix3d refFrame, result;

	ReferenceFrame^ next;
	for(next=inter->Frame;next!=frame->ParentRefFrame;next=next->ParentRefFrame)
	{
		refFrame<<next->matrix3x3[0],next->matrix3x3[1],next->matrix3x3[2],
			next->matrix3x3[3],next->matrix3x3[4],next->matrix3x3[5],
			next->matrix3x3[6],next->matrix3x3[7],next->matrix3x3[8];
		A=refFrame*A*refFrame.transpose();
	}

	for(int i=0;i<9;i++) inter->matrix3x3[i]=A(i);
}

System::Void ReferenceFramesDictionary::MakeFrameLabFrame(ReferenceFrame^ frame)
{
	Matrix3d A;
	A<<frame->matrix3x3[0], frame->matrix3x3[1], frame->matrix3x3[2],
		frame->matrix3x3[3], frame->matrix3x3[4], frame->matrix3x3[5],
		frame->matrix3x3[6], frame->matrix3x3[7], frame->matrix3x3[8];

	Matrix3d refFrame, result;
	result.Identity();

	//Change first old children and interactions
	//calculate the total rotation(merging) from parent to Root
	for(ReferenceFrame^ next=frame;next!=nullptr;next=next->ParentRefFrame)
	{
		refFrame<<next->matrix3x3[0],next->matrix3x3[1],next->matrix3x3[2],
			next->matrix3x3[3],next->matrix3x3[4],next->matrix3x3[5],
			next->matrix3x3[6],next->matrix3x3[7],next->matrix3x3[8];
		result=refFrame*result;
	}

	//Find interactions of the specific frame and change them
	for each (int i in Interactions->Keys)
		if(i>0 && ((Tensor ^)Interactions[i])->Frame==frame)
		{
			Matrix3d intermat; 
			intermat<<((Tensor ^)Interactions[i])->matrix3x3[0],
				((Tensor ^)Interactions[i])->matrix3x3[1],
				((Tensor ^)Interactions[i])->matrix3x3[2],
				((Tensor ^)Interactions[i])->matrix3x3[3],
				((Tensor ^)Interactions[i])->matrix3x3[4],
				((Tensor ^)Interactions[i])->matrix3x3[5],
				((Tensor ^)Interactions[i])->matrix3x3[6],
				((Tensor ^)Interactions[i])->matrix3x3[7],
				((Tensor ^)Interactions[i])->matrix3x3[8];

			intermat=result* intermat*result.transpose();
			for(int ii=0;ii<9;ii++) ((Tensor ^)Interactions[i])->matrix3x3[ii]=A(ii);
		}


		//Find Children and change them
		for(int i=frame->getID();i<Count+1;i++)
		{
			if(frame==((ReferenceFrame^)aDictionary[i])->ParentRefFrame)
			{
				ReferenceFrame^ next=((ReferenceFrame^)aDictionary[i]);
				refFrame<<next->matrix3x3[0],next->matrix3x3[1],next->matrix3x3[2],
					next->matrix3x3[3],next->matrix3x3[4],next->matrix3x3[5],
					next->matrix3x3[6],next->matrix3x3[7],next->matrix3x3[8];
				refFrame=result*refFrame;
				for(int j=0;j<9;j++) ((ReferenceFrame^)aDictionary[i])->matrix3x3[j]=refFrame(j);
			}
		}



		//Change the parent
		//Save the old value, will used later
		Matrix3d temp;
		temp<<frame->ParentRefFrame->matrix3x3[0], frame->ParentRefFrame->matrix3x3[1], frame->ParentRefFrame->matrix3x3[2],
			frame->ParentRefFrame->matrix3x3[3], frame->ParentRefFrame->matrix3x3[4], frame->ParentRefFrame->matrix3x3[5],
			frame->ParentRefFrame->matrix3x3[6], frame->ParentRefFrame->matrix3x3[7], frame->ParentRefFrame->matrix3x3[8];
		//
		result=result*A.transpose();
		for(int j=0;j<9;j++) frame->ParentRefFrame->matrix3x3[j]=result(j);

		//Change the ascendants
		Matrix3d swap;
		for(ReferenceFrame^ next=frame->ParentRefFrame->ParentRefFrame;next!=nullptr;next=next->ParentRefFrame)
		{
			//Make swap
			swap=temp.transpose();
			temp<<next->matrix3x3[0],next->matrix3x3[1],next->matrix3x3[2],
				next->matrix3x3[3],next->matrix3x3[4],next->matrix3x3[5],
				next->matrix3x3[6],next->matrix3x3[7],next->matrix3x3[8];
			for(int j=0;j<9;j++) next->matrix3x3[j]=swap(j);
		}

		//Change the ascendants, parents
		ReferenceFrame^ swapRef,^newparent;
		newparent=frame;
		for(ReferenceFrame^ next=frame->ParentRefFrame;next!=nullptr;next=swapRef)
		{
			//Make swap
			swapRef=next->ParentRefFrame;
			next->ParentRefFrame=newparent;
			newparent=next;

		}

		//Finaly change the new root properties
		frame->ParentRefFrame=nullptr;
		A.Identity();
		for(int j=0;j<9;j++) frame->matrix3x3[j]=A(j);


		//Renumber IDs
		//TODO


		//Renumber frames for continous IDs
		Dictionary <int, ReferenceFrame^> ^ tempDictionary=gcnew Dictionary <int, ReferenceFrame^>();
		int jj=1;
		frame->label="Old ["+frame->ID+"]";
		frame->ID=jj;
		tempDictionary->Add(jj, frame); 
		ReIDRecurcively( tempDictionary, frame, jj);


		aDictionary->Clear();
		aDictionary= tempDictionary;


}

System::Void ReferenceFramesDictionary::ReIDRecurcively(Dictionary <int, ReferenceFrame^> ^% tempDictionary, ReferenceFrame^ Parent, int & currentID)
{
	for each(int j in aDictionary->Keys)
	{
		if(Parent==((ReferenceFrame^)aDictionary[j])->ParentRefFrame)
		{
			((ReferenceFrame^)aDictionary[j])->label=
				"Old ["+((ReferenceFrame^)aDictionary[j])->ID+"]";
			((ReferenceFrame^)aDictionary[j])->ID=++currentID;
			tempDictionary->Add(currentID, ((ReferenceFrame^)aDictionary[j]));
			ReIDRecurcively(tempDictionary, ((ReferenceFrame^)aDictionary[j]), currentID);
		}
	}
}


bool ReferenceFramesDictionary::CheckDescendantRecurcively(ReferenceFrame^ Parent, ReferenceFrame^ Descendant)
{
	if(Parent->ParentRefFrame==nullptr) return false;

	if(Parent==Descendant) return true;
	else return CheckDescendantRecurcively(Parent, Descendant->ParentRefFrame);

}

System::Void ReferenceFramesDictionary::RemoveAt(int aID) 
{


	if(aID==1 || !aDictionary->ContainsKey(aID)) //Can not delete Root
		throw gcnew System::String("Cannot delete this frame.");
	else
	{
		OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
			gcnew KeyValuePair<int, ReferenceFrame^>(aID, ((ReferenceFrame ^)aDictionary[aID]))));

		//Save the parent of the deleted child
		int jj=aDictionary[aID]->ParentRefFrame->getID();
		int fin=newID;


		//Update frame orphaned interactions
		for each (int i in Interactions->Keys)
			if(i>0) 
			{
				for(ReferenceFrame^ next=((Tensor ^)Interactions[i])->Frame;
					next!=nullptr && next!=aDictionary[aID]->ParentRefFrame;
					next=next->ParentRefFrame)
					if(next==aDictionary[aID]) 
					{
						TransformToFrame((ReferenceFrame ^ )this[aID],((Tensor ^)Interactions[i]));
						((Tensor ^)Interactions[i])->Frame=this[jj];
					};
			};


			//Erase parentless children
			for(int i=aID+1;i<fin;i++) 
			{
				//Check if the childer has a parent
				if(aID==aDictionary[i]->ParentRefFrame->getID())
				{
					aDictionary->Remove(i);
					newID--;
				};
			};

			//Delete frame
			aDictionary->Remove(aID);
			newID--;

			//Renumber frames for continous IDs
			Dictionary <int, ReferenceFrame^> ^ tempDictionary=gcnew Dictionary <int, ReferenceFrame^>();
			int j=1;
			Dictionary <int, ReferenceFrame^> ^temp=gcnew Dictionary <int, ReferenceFrame^>();
			for each(int i in aDictionary->Keys)
			{
				((ReferenceFrame^)aDictionary[i])->ID=j;
				temp->Add(j, (ReferenceFrame^)aDictionary[i]); 
				j++;
			};
			aDictionary->Clear();
			aDictionary=temp;

	}

};
System::Void ReferenceFramesDictionary::Clear()
{
	aDictionary->Clear();
	newID=2;

	//Create lab-root reference frame
	::Matrix3x3 ^Matrix=gcnew ::Matrix3x3();
	Matrix[0]=1.0; Matrix[4]=1.0; Matrix[8]=1.0;
	Matrix[1]=0.0; Matrix[2]=0.0; Matrix[3]=0.0; 
	Matrix[5]=0.0; Matrix[6]=0.0; Matrix[7]=0.0;
	ReferenceFrame^ frame=gcnew ReferenceFrame(Matrix);
	frame->ID=1;
	frame->ParentRefFrame=nullptr;
	frame->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(
		this,&ReferenceFramesDictionary::ReferenceFramesDictionaryChange);
	aDictionary->Add(1,frame); 

};

System::Void ReferenceFramesDictionary::Add(ReferenceFrame^ frame)
{
	frame->ID=newID;
	aDictionary->Add(newID,frame); 
	newID++;

	//For the new ReferenceFrame add event handler
	frame->PropertyChanged+=gcnew System::ComponentModel::PropertyChangedEventHandler(
		this,&ReferenceFramesDictionary::ReferenceFramesDictionaryChange);


	//Event Handler
	OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Add, 
		gcnew KeyValuePair<int, ReferenceFrame^>(newID, frame)));


};

System::Void ReferenceFramesDictionary::ReferenceFramesDictionaryChange(System::Object ^ sender,
																		System::ComponentModel::PropertyChangedEventArgs^ e) 
{
	//recalculate for each interactrion the eigen vector and eigenvalues for the new ref frame

	if(Interactions->Count>0) 
		for each(int i in Interactions->Keys)
		{
			if(i>0 &&((Tensor ^)Interactions[i])->Frame->ID==((ReferenceFrame ^) sender)->ID) 
				((Tensor ^)Interactions[i])->Calculate_EigenStates();
		};

		OnCollectionChanged(gcnew NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction::Remove, 
			gcnew KeyValuePair<int, ReferenceFrame^>(
			((ReferenceFrame^) sender)->getID(), 
			((ReferenceFrame^) sender))));
};

#pragma endregion

#pragma region Model

/**
* @brief Function for making a specific interaction orientation, the lab frame.
* @param ID The interaction ID.
*/
System::Void Model::MakeInteractionLabFrame(int ID)
{
	Matrix3d A;
	A<<((Tensor ^)InteractionCollection[ID])->matrix3x3[0],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[1],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[2],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[3],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[4],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[5],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[6],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[7],
		((Tensor ^)InteractionCollection[ID])->matrix3x3[8];

	SelfAdjointEigenSolver<Matrix3d> eigensolver(A);
	if (eigensolver.info() != Success) abort();
	Matrix3d Q=eigensolver.eigenvectors();
	Matrix3d QInv=eigensolver.eigenvectors().inverse();


	for each(int i in AtomCollection->Keys)
	{
		Matrix3d XYZ;
		XYZ<<AtomCollection[i]->X, 0.0, 0.0,
			AtomCollection[i]->Y, 0.0, 0.0,
			AtomCollection[i]->Z, 0.0, 0.0;
		XYZ=QInv*XYZ;
		AtomCollection[i]->X=XYZ(0); 
		AtomCollection[i]->Y=XYZ(1);
		AtomCollection[i]->Z=XYZ(2);
	};

	for each(int j in InteractionCollection->Keys)
	{
		if(InteractionCollection[j]->IntKind!=InteractionKind::CBond)
		{
			Matrix3d matrix;
			matrix<<    ((Tensor ^)InteractionCollection[j])->matrix3x3[0],
				((Tensor ^)InteractionCollection[j])->matrix3x3[1],
				((Tensor ^)InteractionCollection[j])->matrix3x3[2],
				((Tensor ^)InteractionCollection[j])->matrix3x3[3],
				((Tensor ^)InteractionCollection[j])->matrix3x3[4],
				((Tensor ^)InteractionCollection[j])->matrix3x3[5],
				((Tensor ^)InteractionCollection[j])->matrix3x3[6],
				((Tensor ^)InteractionCollection[j])->matrix3x3[7],
				((Tensor ^)InteractionCollection[j])->matrix3x3[8];
			matrix=QInv*(matrix*Q);

			for(int i=0;i<9;i++) ((Tensor ^)InteractionCollection[j])->matrix3x3[i]=matrix(i);

		}
	};

	OnPropertyChanged(gcnew PropertyChangedEventArgs("Lab reference frame change"));

}

/**
* @brief Constructor of the model.
*/
Model::Model(System::Void)
{
	//Construct the atoms, interactions and reference frames collections
	InteractionCollection=gcnew InteractionsDictionary();
	AtomCollection=gcnew  AtomsDictionary(InteractionCollection);
	RefFrameCollection=gcnew ReferenceFramesDictionary(InteractionCollection);

	//Connect the events of the collections with the event handlers 
	AtomCollection->CollectionChanged+=gcnew System::Collections::Specialized::NotifyCollectionChangedEventHandler(this,&Model::ModelChange);
	InteractionCollection->CollectionChanged+=gcnew System::Collections::Specialized::NotifyCollectionChangedEventHandler(this,&Model::ModelChange);
	RefFrameCollection->CollectionChanged+=gcnew System::Collections::Specialized::NotifyCollectionChangedEventHandler(this,&Model::ModelChange);
}

/**
* @brief Copy Constructor of the model.
* @param aModel The model to be copied.
*/
Model::Model( const Model % aModel )
{
	//Copy each atom, interaction and reference frame

	for each(int i in aModel.RefFrameCollection->Keys)
	{
		RefFrameCollection->Add(aModel.RefFrameCollection[i]);
	};

	for each(int i in aModel.AtomCollection->Keys)
	{
		AtomCollection->Add(aModel.AtomCollection[i]);
	};
	for each(int i in aModel.InteractionCollection->Keys)
	{
		InteractionCollection->Add(aModel.InteractionCollection[i]);
	};
}

/**
* @brief Copy assignment Constructor of the model.
* @param aModel The model to be copied.
*/
Model% Model::operator=(Model aModel )
{
	//Swap each collecton
	swap( RefFrameCollection, aModel.RefFrameCollection );
	swap( AtomCollection, aModel.AtomCollection );
	swap( InteractionCollection, aModel.InteractionCollection );

	//return the current object
	return *this;
}

/**
* @brief Event Handler when the model is changed to 
* call the handler of model which is the OnPropertyChanged
* @param sender The object that fire this event.
* @param e Arguments for when an property changed. Usually a string.
*/
System::Void Model::ModelChange(System::Object ^ sender,System::Collections::Specialized::NotifyCollectionChangedEventArgs^ e)
{

	OnPropertyChanged(gcnew PropertyChangedEventArgs(sender->ToString())); //Model
}

#pragma endregion



