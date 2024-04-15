#include "stdafx.h"


using namespace System;
using namespace System::Text;
using namespace System::Collections::Generic;
using namespace Microsoft::VisualStudio::TestTools::UnitTesting;

    
namespace TestSpinachGUI
{
	[TestClass]
	public ref class UnitTest
	{
	private:
		TestContext^ testContextInstance;

	public: 
		/// <summary>
		///Gets or sets the test context which provides
		///information about and functionality for the current test run.
		///</summary>
		property Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ TestContext
		{
			Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ get()
			{
				return testContextInstance;
			}
			System::Void set(Microsoft::VisualStudio::TestTools::UnitTesting::TestContext^ value)
			{
				testContextInstance = value;
			}
		};

		#pragma region Additional test attributes
		//
		//You can use the following additional attributes as you write your tests:
		//
		//Use ClassInitialize to run code before running the first test in the class
		//[ClassInitialize()]
		//static void MyClassInitialize(TestContext^ testContext) {};
		//
		//Use ClassCleanup to run code after all tests in a class have run
		//[ClassCleanup()]
		//static void MyClassCleanup() {};
		//
		//Use TestInitialize to run code before running each test
		//[TestInitialize()]
		//void MyTestInitialize() {};
		//
		//Use TestCleanup to run code after each test has run
		//[TestCleanup()]
		//void MyTestCleanup() {};
		//
		#pragma endregion 

		[TestMethod]
		void TestMethodGaussAlanine()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\alanine.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussDcb_anion()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\1,3-dcb_anion.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussAnthraquinone_disulphonate_anion()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\anthraquinone_disulphonate_anion.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussAnti_scan_190()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\anti_scan_190.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussBenzoquinone()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\benzoquinone.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussBicyclopropylidene()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\bicyclopropylidene.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussCamphor()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\camphor.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussChrysene_cation()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\chrysene_cation.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussCis_dimethyl()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\cis_dimethyl.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussCrystal_str()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\crystal_str.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussCyclopentyl()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\cyclopentyl.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussD4bicyclopropylidene()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\d4bicyclopropylidene.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussDiacetylene()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\diacetylene.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussFdnb()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\fdnb.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussGlycine()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\glycine.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussMethyl()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\methyl.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussMethylaziridine()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\methylaziridine.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussMethylaziridine_a()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\methylaziridine_a.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussMethylaziridine_a_quad()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\methylaziridine_a_quad.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussMethylaziridine_b()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\methylaziridine_b.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussNapthalenetetrone()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\napthalenetetrone.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussNitroxide()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\nitroxide.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussParafluorotoluene()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\parafluorotoluene.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPerfluoropyrene_cation()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\perfluoropyrene_cation.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPerfluoropyrene_neutral()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\perfluoropyrene_neutral.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPhenyl()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\phenyl.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPhenylaziridine_al()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\phenylaziridine_a.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPhenylthiaz_cis()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\phenylthiaz_cis.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPhenylthiaz_trans()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\phenylthiaz_trans.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPyrene_cation()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\pyrene_cation.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussPyrene_neutral()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\pyrene_neutral.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussStrychnine()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\strychnine.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussSucrose()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\sucrose.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussTma()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\tma.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussTrp_xray()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\trp_xray.out", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussTryptophan_neutral_radical()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\tryptophan_neutral_radical.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussUrea()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\urea.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussAla()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\ala.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussArg()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\arg.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussAsn()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\asn.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussAsp()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\asp.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		};

		[TestMethod]
		void TestMethodGaussGln()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\gln.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussGlu()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\glu.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussGly()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\gly.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussHis()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\his.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussIle()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\ile.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussLeu()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\leu.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussLys()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\lys.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussMet()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\met.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussPhe()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\phe.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussPro()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\pro.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussSer()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\ser.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussThr()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\thr.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussTrp()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\trp.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussTyr()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\tyr.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};

		[TestMethod]
		void TestMethodGaussVal()
		{
			Gauss^ OpenedFile;	
			OpenedFile= gcnew Gauss("Z:\\SpinachGUI\\examples\\GaussView\\amino_acids\\val.log", gcnew Model());
			Assert::IsTrue(OpenedFile->LoadFile());
		
		};
	};
}
