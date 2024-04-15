#pragma once
#include "IOSpinSystem.h"
#include "../System Core/orientation.h"

using namespace SpinachGUI;

namespace SpinachGUI {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/** \class  Simpson
	*  Simpson class, for writing Simpson format
	*  For systems with no electrons, exporting Chemical shifts, J-couplings, Dipolar interactions
	*  and Quadrupolar interactions.
	*/
	public ref class Simpson : public  System::Windows::Forms::Form
	{
	public:
		Simpson( )
		{
			InitializeComponent();

			//Setting the parameters for the dipolar threshold control
			DipolarThreshold->Minimum=Convert::ToDecimal(1.0);
			DipolarThreshold->Maximum=Convert::ToDecimal(1000.0);
			DipolarThreshold->Increment=Convert::ToDecimal(0.2);
			DipolarThreshold->Value=Convert::ToDecimal(10.00);

		}

#pragma region Autogenerated members
	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~Simpson()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::CheckBox^  SortcheckBox;
	private: System::Windows::Forms::Button^  Exportbutton;
	private: System::Windows::Forms::Button^  Cancelbutton;
	private: System::Windows::Forms::ComboBox^  OrdercomboBox;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::TableLayoutPanel^  tableLayoutPanel13;
	public: System::Windows::Forms::DataGridView^  ChanneldataGridView;
	private: System::Windows::Forms::Label^  label10;
	private: System::Windows::Forms::DataGridViewCheckBoxColumn^  Column1;
	private: System::Windows::Forms::DataGridViewTextBoxColumn^  Column4;
	private: System::Windows::Forms::NumericUpDown^  DipolarThreshold;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog;



	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>
		System::ComponentModel::Container ^components;
#pragma endregion 

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			System::Windows::Forms::DataGridViewCellStyle^  dataGridViewCellStyle4 = (gcnew System::Windows::Forms::DataGridViewCellStyle());
			System::Windows::Forms::DataGridViewCellStyle^  dataGridViewCellStyle5 = (gcnew System::Windows::Forms::DataGridViewCellStyle());
			System::Windows::Forms::DataGridViewCellStyle^  dataGridViewCellStyle6 = (gcnew System::Windows::Forms::DataGridViewCellStyle());
			this->SortcheckBox = (gcnew System::Windows::Forms::CheckBox());
			this->Exportbutton = (gcnew System::Windows::Forms::Button());
			this->Cancelbutton = (gcnew System::Windows::Forms::Button());
			this->OrdercomboBox = (gcnew System::Windows::Forms::ComboBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->tableLayoutPanel13 = (gcnew System::Windows::Forms::TableLayoutPanel());
			this->ChanneldataGridView = (gcnew System::Windows::Forms::DataGridView());
			this->Column1 = (gcnew System::Windows::Forms::DataGridViewCheckBoxColumn());
			this->Column4 = (gcnew System::Windows::Forms::DataGridViewTextBoxColumn());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->DipolarThreshold = (gcnew System::Windows::Forms::NumericUpDown());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->saveFileDialog = (gcnew System::Windows::Forms::SaveFileDialog());
			this->tableLayoutPanel13->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->ChanneldataGridView))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->DipolarThreshold))->BeginInit();
			this->SuspendLayout();
			// 
			// SortcheckBox
			// 
			this->SortcheckBox->AutoSize = true;
			this->SortcheckBox->Location = System::Drawing::Point(157, 52);
			this->SortcheckBox->Name = L"SortcheckBox";
			this->SortcheckBox->Size = System::Drawing::Size(175, 17);
			this->SortcheckBox->TabIndex = 0;
			this->SortcheckBox->Text = L"Sort atoms according to isootpe";
			this->SortcheckBox->UseVisualStyleBackColor = true;
			// 
			// Exportbutton
			// 
			this->Exportbutton->Location = System::Drawing::Point(55, 229);
			this->Exportbutton->Name = L"Exportbutton";
			this->Exportbutton->Size = System::Drawing::Size(75, 23);
			this->Exportbutton->TabIndex = 1;
			this->Exportbutton->Text = L"Export";
			this->Exportbutton->UseVisualStyleBackColor = true;
			this->Exportbutton->Click += gcnew System::EventHandler(this, &Simpson::Exportbutton_Click);
			// 
			// Cancelbutton
			// 
			this->Cancelbutton->Location = System::Drawing::Point(220, 228);
			this->Cancelbutton->Name = L"Cancelbutton";
			this->Cancelbutton->Size = System::Drawing::Size(75, 23);
			this->Cancelbutton->TabIndex = 2;
			this->Cancelbutton->Text = L"Cancel";
			this->Cancelbutton->UseVisualStyleBackColor = true;
			this->Cancelbutton->Click += gcnew System::EventHandler(this, &Simpson::Cancelbutton_Click);
			// 
			// OrdercomboBox
			// 
			this->OrdercomboBox->FormattingEnabled = true;
			this->OrdercomboBox->Items->AddRange(gcnew cli::array< System::Object^  >(2) {L"1st", L"2nd"});
			this->OrdercomboBox->Location = System::Drawing::Point(169, 10);
			this->OrdercomboBox->Name = L"OrdercomboBox";
			this->OrdercomboBox->Size = System::Drawing::Size(45, 21);
			this->OrdercomboBox->TabIndex = 3;
			this->OrdercomboBox->Text = L"1st";
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(9, 13);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(152, 13);
			this->label1->TabIndex = 4;
			this->label1->Text = L"Order of quadrupolar couplings";
			// 
			// tableLayoutPanel13
			// 
			this->tableLayoutPanel13->Anchor = static_cast<System::Windows::Forms::AnchorStyles>(((System::Windows::Forms::AnchorStyles::Top | System::Windows::Forms::AnchorStyles::Bottom) 
				| System::Windows::Forms::AnchorStyles::Left));
			this->tableLayoutPanel13->CellBorderStyle = System::Windows::Forms::TableLayoutPanelCellBorderStyle::Single;
			this->tableLayoutPanel13->ColumnCount = 1;
			this->tableLayoutPanel13->ColumnStyles->Add((gcnew System::Windows::Forms::ColumnStyle(System::Windows::Forms::SizeType::Percent, 
				100)));
			this->tableLayoutPanel13->Controls->Add(this->ChanneldataGridView, 0, 1);
			this->tableLayoutPanel13->Controls->Add(this->label10, 0, 0);
			this->tableLayoutPanel13->Location = System::Drawing::Point(6, 37);
			this->tableLayoutPanel13->Name = L"tableLayoutPanel13";
			this->tableLayoutPanel13->RowCount = 2;
			this->tableLayoutPanel13->RowStyles->Add((gcnew System::Windows::Forms::RowStyle(System::Windows::Forms::SizeType::Absolute, 
				20)));
			this->tableLayoutPanel13->RowStyles->Add((gcnew System::Windows::Forms::RowStyle()));
			this->tableLayoutPanel13->Size = System::Drawing::Size(137, 163);
			this->tableLayoutPanel13->TabIndex = 6;
			// 
			// ChanneldataGridView
			// 
			this->ChanneldataGridView->AllowUserToAddRows = false;
			this->ChanneldataGridView->AllowUserToDeleteRows = false;
			this->ChanneldataGridView->AllowUserToResizeColumns = false;
			this->ChanneldataGridView->AllowUserToResizeRows = false;
			this->ChanneldataGridView->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((((System::Windows::Forms::AnchorStyles::Top | System::Windows::Forms::AnchorStyles::Bottom) 
				| System::Windows::Forms::AnchorStyles::Left) 
				| System::Windows::Forms::AnchorStyles::Right));
			dataGridViewCellStyle4->Alignment = System::Windows::Forms::DataGridViewContentAlignment::MiddleCenter;
			dataGridViewCellStyle4->BackColor = System::Drawing::SystemColors::Control;
			dataGridViewCellStyle4->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, 
				System::Drawing::GraphicsUnit::Point, static_cast<System::Byte>(0)));
			dataGridViewCellStyle4->ForeColor = System::Drawing::SystemColors::WindowText;
			dataGridViewCellStyle4->SelectionBackColor = System::Drawing::SystemColors::Highlight;
			dataGridViewCellStyle4->SelectionForeColor = System::Drawing::SystemColors::HighlightText;
			dataGridViewCellStyle4->WrapMode = System::Windows::Forms::DataGridViewTriState::True;
			this->ChanneldataGridView->ColumnHeadersDefaultCellStyle = dataGridViewCellStyle4;
			this->ChanneldataGridView->ColumnHeadersHeightSizeMode = System::Windows::Forms::DataGridViewColumnHeadersHeightSizeMode::AutoSize;
			this->ChanneldataGridView->Columns->AddRange(gcnew cli::array< System::Windows::Forms::DataGridViewColumn^  >(2) {this->Column1, 
				this->Column4});
			dataGridViewCellStyle5->Alignment = System::Windows::Forms::DataGridViewContentAlignment::MiddleCenter;
			dataGridViewCellStyle5->BackColor = System::Drawing::SystemColors::Window;
			dataGridViewCellStyle5->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 8.25F, System::Drawing::FontStyle::Regular, 
				System::Drawing::GraphicsUnit::Point, static_cast<System::Byte>(0)));
			dataGridViewCellStyle5->ForeColor = System::Drawing::SystemColors::ControlText;
			dataGridViewCellStyle5->SelectionBackColor = System::Drawing::Color::Pink;
			dataGridViewCellStyle5->SelectionForeColor = System::Drawing::SystemColors::ControlText;
			dataGridViewCellStyle5->WrapMode = System::Windows::Forms::DataGridViewTriState::False;
			this->ChanneldataGridView->DefaultCellStyle = dataGridViewCellStyle5;
			this->ChanneldataGridView->EditMode = System::Windows::Forms::DataGridViewEditMode::EditOnEnter;
			this->ChanneldataGridView->Location = System::Drawing::Point(4, 25);
			this->ChanneldataGridView->Name = L"ChanneldataGridView";
			dataGridViewCellStyle6->Alignment = System::Windows::Forms::DataGridViewContentAlignment::MiddleLeft;
			dataGridViewCellStyle6->BackColor = System::Drawing::SystemColors::Control;
			dataGridViewCellStyle6->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 7.471698F, System::Drawing::FontStyle::Regular, 
				System::Drawing::GraphicsUnit::Point, static_cast<System::Byte>(0)));
			dataGridViewCellStyle6->ForeColor = System::Drawing::SystemColors::WindowText;
			dataGridViewCellStyle6->SelectionBackColor = System::Drawing::SystemColors::Highlight;
			dataGridViewCellStyle6->SelectionForeColor = System::Drawing::SystemColors::HighlightText;
			dataGridViewCellStyle6->WrapMode = System::Windows::Forms::DataGridViewTriState::True;
			this->ChanneldataGridView->RowHeadersDefaultCellStyle = dataGridViewCellStyle6;
			this->ChanneldataGridView->RowHeadersVisible = false;
			this->ChanneldataGridView->RowHeadersWidth = 39;
			this->ChanneldataGridView->Size = System::Drawing::Size(129, 134);
			this->ChanneldataGridView->TabIndex = 0;
			// 
			// Column1
			// 
			this->Column1->FalseValue = L"0";
			this->Column1->HeaderText = L"Enabled";
			this->Column1->Name = L"Column1";
			this->Column1->Resizable = System::Windows::Forms::DataGridViewTriState::True;
			this->Column1->SortMode = System::Windows::Forms::DataGridViewColumnSortMode::Automatic;
			this->Column1->TrueValue = L"1";
			this->Column1->Width = 45;
			// 
			// Column4
			// 
			this->Column4->HeaderText = L"Isotope";
			this->Column4->Name = L"Column4";
			this->Column4->ReadOnly = true;
			this->Column4->Resizable = System::Windows::Forms::DataGridViewTriState::True;
			this->Column4->SortMode = System::Windows::Forms::DataGridViewColumnSortMode::NotSortable;
			this->Column4->Width = 60;
			// 
			// label10
			// 
			this->label10->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((((System::Windows::Forms::AnchorStyles::Top | System::Windows::Forms::AnchorStyles::Bottom) 
				| System::Windows::Forms::AnchorStyles::Left) 
				| System::Windows::Forms::AnchorStyles::Right));
			this->label10->AutoSize = true;
			this->label10->BackColor = System::Drawing::Color::Gray;
			this->label10->ForeColor = System::Drawing::SystemColors::ControlLightLight;
			this->label10->Location = System::Drawing::Point(1, 1);
			this->label10->Margin = System::Windows::Forms::Padding(0);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(135, 20);
			this->label10->TabIndex = 0;
			this->label10->Text = L"Channels";
			this->label10->TextAlign = System::Drawing::ContentAlignment::MiddleCenter;
			// 
			// DipolarThreshold
			// 
			this->DipolarThreshold->DecimalPlaces = 2;
			this->DipolarThreshold->Location = System::Drawing::Point(242, 118);
			this->DipolarThreshold->Name = L"DipolarThreshold";
			this->DipolarThreshold->Size = System::Drawing::Size(55, 20);
			this->DipolarThreshold->TabIndex = 7;
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(156, 95);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(165, 39);
			this->label2->TabIndex = 8;
			this->label2->Text = L"Do not export dipolar interactions \r\n\r\nfor distances >                         �";
			// 
			// Simpson
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(334, 262);
			this->Controls->Add(this->DipolarThreshold);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->tableLayoutPanel13);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->OrdercomboBox);
			this->Controls->Add(this->Cancelbutton);
			this->Controls->Add(this->Exportbutton);
			this->Controls->Add(this->SortcheckBox);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedToolWindow;
			this->Name = L"Simpson";
			this->ShowInTaskbar = false;
			this->Text = L"Simpson Export";
			this->tableLayoutPanel13->ResumeLayout(false);
			this->tableLayoutPanel13->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->ChanneldataGridView))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->DipolarThreshold))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

#pragma region Non-autogenerated members
		public:	 void WriteFile(System::String^ );
		public:  void Initialize_Simpson(Model^ model, String^ titlefile);
		private: FileStream^ WritingFile;   ///< The stream that has the file which will be written
		private: Model^ SystemModel;		///< The  model where imported data will be saved
		private: String ^ FileName;			///< The name of the File to read or write
#pragma endregion 

#pragma region Handlers
private: System::Void Exportbutton_Click(System::Object^  , System::EventArgs^  );
private: System::Void Cancelbutton_Click(System::Object^  sender, System::EventArgs^  e) {Close(); }
#pragma endregion
};

/** \class  ComparerElement
*  ComparerElement class, inherits from ICmparer
*  For comparison of elements when Atoms are given
*/
ref class ComparerElement: public Collections::IComparer
{
private:

   // Calls CaseInsensitiveComparer.Compare with the parameters reversed.
   virtual int Compare( Object^ x, Object^ y ) sealed = Collections::IComparer::Compare
   {
      return ((gcnew CaseInsensitiveComparer)->Compare( ((Atom^)x)->isotope->Element, ((Atom^)y)->isotope->Element ));
   }

};

}

