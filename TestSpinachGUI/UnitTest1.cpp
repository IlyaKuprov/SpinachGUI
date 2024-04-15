#include "stdafx.h"

using namespace System;
using namespace System::Text;
using namespace System::Collections::Generic;
using namespace	Microsoft::VisualStudio::TestTools::UnitTesting;

namespace TestSpinachGUI
{
	[TestClass]
	public ref class UnitTestXYZ
	{
	public: 
		
		[TestMethod]
		void TestMethodXYZUbiquitin()
		{
			SpinachGUI::XYZ^ OpenedFile;
			OpenedFile= gcnew SpinachGUI::XYZ("Z:\\SpinachGUI\\examples\\XYZ\\a_ubiquitin.xyz", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};
		

		[TestMethod]
	    void TestMethodXYZMethane()
		{
			SpinachGUI::XYZ^ OpenedFile;
			OpenedFile= gcnew SpinachGUI::XYZ("Z:\\SpinachGUI\\examples\\XYZ\\methane.xyz", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodXYZNonMethane()
		{
			SpinachGUI::XYZ^ OpenedFile;
			OpenedFile= gcnew SpinachGUI::XYZ("Z:\\SpinachGUI\\examples\\XYZ\\methane1.xyz", gcnew Model());
			Assert::IsFalse(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodCOSMOSAspAlaFUM()
		{
			COSMOS^ OpenedFile;
			OpenedFile= gcnew COSMOS("Z:\\SpinachGUI\\examples\\COSMOS\\AspAlaFUMTAI_6_Mol_1H_3J.coo", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodADFadf_example()
		{
			ADF^ OpenedFile;
			OpenedFile= gcnew ADF("Z:\\SpinachGUI\\examples\\ADF\\adf_example.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodMOLAmfetamine()
		{
			MOL^ OpenedFile;
			OpenedFile= gcnew MOL("Z:\\SpinachGUI\\examples\\MOL\\Amfetamine.mol", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodMOLAminoglutethimide()
		{
			MOL^ OpenedFile;
			OpenedFile= gcnew MOL("Z:\\SpinachGUI\\examples\\MOL\\Aminoglutethimide.mol", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodMOLBarbituricacid()
		{
			MOL^ OpenedFile;
			OpenedFile= gcnew MOL("Z:\\SpinachGUI\\examples\\MOL\\Barbituric acid.mol", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodGAMESTyr()
		{
			GAMESS^ OpenedFile;
			OpenedFile= gcnew GAMESS("Z:\\SpinachGUI\\examples\\GAMESS\\tyr.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodCastepAlanine()
		{
			Castep^ OpenedFile;
			OpenedFile= gcnew Castep("Z:\\SpinachGUI\\examples\\Magres\\alanine.magres", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodCastepEthanol()
		{
			Castep^ OpenedFile;
			OpenedFile= gcnew Castep("Z:\\SpinachGUI\\examples\\Magres\\ethanol-jc.magres", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodCastepEthanolnmr()
		{
			Castep^ OpenedFile;
			OpenedFile= gcnew Castep("Z:\\SpinachGUI\\examples\\Magres\\ethanol-nmr.magres", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodCastepGlycine()
		{
			Castep^ OpenedFile;
			OpenedFile= gcnew Castep("Z:\\SpinachGUI\\examples\\Magres\\glycine.magres", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodOrcaNBiradOpt()
		{
			Orca^ OpenedFile;
			OpenedFile= gcnew Orca("Z:\\SpinachGUI\\examples\\Orca\\N-BiradOpt.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodOrcaNitroxide()
		{
			Orca^ OpenedFile;
			OpenedFile= gcnew Orca("Z:\\SpinachGUI\\examples\\Orca\\nitroxide.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
	    void TestMethodOrcaOrca_chrysene_cation_radical()
		{
			Orca^ OpenedFile;
			OpenedFile= gcnew Orca("Z:\\SpinachGUI\\examples\\Orca\\orca_chrysene_cation_radical.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

	};
}
