
#ifndef __MATHTYPES___H_
#define __MATHTYPES___H_

#include <cstring>
#include <string>
#include <Dense>
#include <Geometry>


using std::complex;
using namespace Eigen;

namespace SpinachGUI {
    ///Euler angle type
public ref class EulerAngles {

 public:
 	 double alpha,beta,gamma;
	 EulerAngles() : alpha(0),beta(0),gamma(0) { }
     EulerAngles(double _alpha,double _beta, double _gamma): alpha(_alpha),beta(_beta),gamma(_gamma) {}
     void Set(double _alpha,double _beta, double _gamma) {alpha=_alpha;  beta= _beta; gamma=_gamma; }
	 void Normalize() { }
     EulerAngles^ Normalized() { return this;}


	 bool operator==(EulerAngles o)  { return alpha == o.alpha &&  beta == o.beta && gamma == o.gamma;}
	 bool operator!=(EulerAngles o) { return alpha != o.alpha ||  beta != o.beta || gamma != o.gamma;}

  
 };



public ref class Matrix3x3 {

 public:
 	 double xx,xy,xz,yx,yy,yz,zx,zy,zz;

	 Matrix3x3() : xx(0),xy(0),xz(0),yx(0),yy(0),yz(0),zx(0),zy(0),zz(0) { matrix3d=new  Eigen::Matrix3d();}
	 Eigen::Matrix3d* matrix3d;
     //Matrix3d(double _alpha,double _beta, double _gamma): alpha(_alpha),beta(_beta),gamma(_gamma) {}
     //void Set(double _alpha,double _beta, double _gamma) {alpha=_alpha;  beta= _beta; gamma=_gamma; }
	 void Normalize() { }
     Matrix3x3^ Normalized() { return this;}

 //private:

	 void toEigen(){(*matrix3d)(0)=xx;(*matrix3d)(1)=xy;(*matrix3d)(2)=xz;
	                (*matrix3d)(3)=yx;(*matrix3d)(4)=yy;(*matrix3d)(5)=yz;
	                (*matrix3d)(6)=zx;(*matrix3d)(7)=zy;(*matrix3d)(8)=zz;
	 };
     void fromEigen(){xx=(*matrix3d)(0);xy=(*matrix3d)(1);xz=(*matrix3d)(2);
	                  yx=(*matrix3d)(3);yy=(*matrix3d)(4);yz=(*matrix3d)(5);
	                  zx=(*matrix3d)(6);zy=(*matrix3d)(7);zz=(*matrix3d)(8);};
	

  
 };
 
public ref class Quaternion {

 public:
 	 double x,y,z,w;
	 Eigen::Quaterniond* quaterniond;
	 Quaternion() : x(0),y(0),z(0),w(0) {quaterniond= new Eigen::Quaterniond(); }
	 	 Quaternion(double _w, double _x, double _y, double _z) 
		 : x(_x),y(_y),z(_z),w(_w) {quaterniond= new Eigen::Quaterniond();  }
	 Quaternion(Quaternion ^quat):x(quat->x),y(quat->y),z(quat->z),w(quat->w){} 
     //Matrix3d(double _alpha,double _beta, double _gamma): alpha(_alpha),beta(_beta),gamma(_gamma) {}
     //void Set(double _alpha,double _beta, double _gamma) {alpha=_alpha;  beta= _beta; gamma=_gamma; }
	 void Normalize() { }
     Quaternion^ Normalized() {this->toEigen(); quaterniond->normalize();this->fromEigen();return this;}

	 //private:

	 void toEigen(){quaterniond->x()=x;quaterniond->y()=y;quaterniond->z()=z;quaterniond->w()=w;};
     void fromEigen(){x=quaterniond->x();y=quaterniond->y();z=quaterniond->z();w=quaterniond->w();};

  
 };

public ref class AngleAxis {

 public:
 	 double x,y,z,angle;
	 Eigen::AngleAxisd* angleaxisd;
	 AngleAxis() : x(0),y(0),z(0),angle(0) {angleaxisd=new Eigen::AngleAxisd(); }
	 AngleAxis(double _x, double _y, double _z, double _angle) 
		 : x(_x),y(_y),z(_z),angle(_angle) {angleaxisd=new Eigen::AngleAxisd(); }
	 AngleAxis(AngleAxis ^angleax):x(angleax->x),y(angleax->y),z(angleax->z),angle(angleax->angle){} 
	 //AngleAxis() : x(0),y(0),z(0),angle(0) { }
 
     //Matrix3d(double _alpha,double _beta, double _gamma): alpha(_alpha),beta(_beta),gamma(_gamma) {}
     //void Set(double _alpha,double _beta, double _gamma) {alpha=_alpha;  beta= _beta; gamma=_gamma; }
	 void Normalize() { }
     AngleAxis^ Normalized() { this->toEigen(); angleaxisd->axis().normalize();this->fromEigen();return this;}

//private:

	 void toEigen(){angleaxisd->axis().x()=x;angleaxisd->axis().y()=y;angleaxisd->axis().z()=z;angleaxisd->angle()=angle;};
	 void fromEigen(){x=angleaxisd->axis().x();y=angleaxisd->axis().y();z=angleaxisd->axis().z();angle=angleaxisd->angle();};
  
 };

 ///Enumeration of the four conventions on storing rotations
 public enum  Type {
            EULER,
            ANGLE_AXIS,
            QUATERNION,
            DCM
 };

///Class for storing a 3 dimentional rotation
public ref  class Orientation {
    public:
//        EIGEN_MAKE_ALIGNED_OPERATOR_NEW;
        ///Constructs the identity rotation
        Orientation(): mType(QUATERNION), mQuaternion(&Eigen::Quaterniond(1,0,0,0)) {Invariant();}
		///Copy constructor
        //Orientation(const Orientation% o) {/*o->Invariant();  this=o;*/};
        ///Constructs an orientation from euler angles
        Orientation(EulerAngles^ ea) : mType(EULER) {mEuler=ea;Invariant(); };
        ///Constructs an orientation from a matrix
		Orientation(Matrix3x3^ m): mType(DCM) {myMatrix=m;Invariant();};
        ///Constructs an orientation from a quaternion
		Orientation(Quaternion^ q): mType(QUATERNION)  {myQuaternion=q;Invariant();};
        ///Constructs an orientation from an AngleAxis
		Orientation(AngleAxis^ aa): mType(ANGLE_AXIS)  {myAngleAxis=aa;Invariant();};
        ///Destructor
        ~Orientation(){};

        ///Normalise the contained rotation in place.
       // void Normalize();
	//	void Normalizem();
        ///Normalise the contained rotation.
        Orientation^ Normalized() ;

		///Operetors
		//Orientation^ operator=(Orientation^ o);
		//Orientation^ operator=(EulerAngles^ ea) {mType = EULER;	mEuler = ea; Invariant(); return this;};
		//Orientation^% operator=(Eigen::AngleAxisd& a){mType = ANGLE_AXIS; *mAngleAxis = a; Invariant(); return this;};
		//Orientation^% operator=(Eigen::Matrix3d& m){mType = DCM; *mMatrix = m; Invariant(); return this;};   
		//Orientation^% operator=(Eigen::Quaterniond& q){mType = QUATERNION; *mQuaternion = q; Invariant(); return this;};

        //bool operator==(Orientation^ o) ;

		//Eigen::Vector3d Apply(Eigen::Vector3d v) ;

        ///Returns the convention that is being used to store the rotation
        SpinachGUI::Type GetType() {return mType;}

        ///If the euler angle convention is being used then this function
        ///will set its arguments to the stored values otherwise the result
        ///is undefined.
        //void GetEuler(double* alpha,double* beta,double* gamma) ;

        ///If the angle axis convention being used then this function will
        ///set its arugments to those values otherwise the result is
        ///undefined.
        //void GetAngleAxis(double* angle,Eigen::Vector3d* axis) ;

        ///If the quaternion convention being used then this function will
        ///set its arguments to those values otherwise the result is
        ///undefined.
        //void GetQuaternion(double* real, double* i, double* j, double* k) ;

        ///If the eigensystem convention is being used then this function
        ///will set its arguments to the appropriate values otherwise the
        ///result is undefined.
	        ///Converts to a rotation matrix

		EulerAngles^ GetAsEuler();
        Matrix3x3^   GetAsDCM();
        SpinachGUI::AngleAxis^  GetAsAngleAxis();
        SpinachGUI::Quaternion^ GetAsQuaternion();



        ///returns a representation of the orientation as a string that is
        ///both machiene parsable and human readable.
        //std::string ToString() ;
        ///Parses an orentation from a string representation. The form of
        ///the representation should be the same as returned by ToString
        //void FromString(std::string string){ cerr << "Not Implimented" << endl;}


		
    private:

		SpinachGUI::Type mType;
		EulerAngles^ mEuler;
		Eigen::AngleAxisd* mAngleAxis;
		AngleAxis^ myAngleAxis;
		Eigen::Quaterniond* mQuaternion;
		Quaternion^ myQuaternion;
		Eigen::Matrix3d* mMatrix;
		Matrix3x3^ myMatrix;
		void Invariant() ;

		
//Rotation Converions
    public:

   	EulerAngles^ ConvertToEuler(EulerAngles^ rot){return rot;};
    EulerAngles^ ConvertToEuler(Matrix3x3^   rot)	{return ConvertToEuler(ConvertToQuaternion(rot));};
    EulerAngles^ ConvertToEuler(SpinachGUI::Quaternion^ rot);
    EulerAngles^ ConvertToEuler(AngleAxis^   rot){return ConvertToEuler(ConvertToQuaternion(rot));};

	Matrix3x3^    ConvertToDCM(EulerAngles^ rot){return ConvertToDCM(ConvertToQuaternion(rot));};
    Matrix3x3^    ConvertToDCM(Matrix3x3^   rot){return rot;};
    Matrix3x3^    ConvertToDCM(Quaternion^ rot)
	{rot->toEigen();
	 Matrix3x3^ result=gcnew Matrix3x3();
	 *result->matrix3d=rot->quaterniond->toRotationMatrix();
	  result->fromEigen(); 
	  return result;};
	Matrix3x3^    ConvertToDCM(AngleAxis^   rot){return ConvertToDCM(ConvertToQuaternion(rot));};


	SpinachGUI::Quaternion^ ConvertToQuaternion(EulerAngles^ rot);
    SpinachGUI::Quaternion^ ConvertToQuaternion(SpinachGUI::Matrix3x3^    rot)
	                  {rot->toEigen();Quaternion^ result=gcnew Quaternion();
						result->quaterniond=new Quaterniond(*rot->matrix3d);
	                    result->fromEigen(); return result;};
    SpinachGUI::Quaternion^ ConvertToQuaternion(SpinachGUI::Quaternion^ rot){return rot;};
    SpinachGUI::Quaternion^ ConvertToQuaternion(AngleAxis^   rot)
	{rot->toEigen();Quaternion^ result=gcnew Quaternion();
						result->quaterniond=new Quaterniond(*rot->angleaxisd);
						result->fromEigen(); return result;};

	AngleAxis^  ConvertToAngleAxis(EulerAngles^ rot){return ConvertToAngleAxis(ConvertToQuaternion(rot));}
    AngleAxis^  ConvertToAngleAxis(Matrix3x3^    rot){return ConvertToAngleAxis(ConvertToQuaternion(rot));};
    AngleAxis^  ConvertToAngleAxis(Quaternion^ rot){
	rot->toEigen();AngleAxis^ result=gcnew AngleAxis();
						result->angleaxisd=new AngleAxisd(*rot->quaterniond);
						result->fromEigen(); return result;	};
    AngleAxis^  ConvertToAngleAxis(AngleAxis^   rot){return rot;};

    //Uniform Rotation Normalisation
    //EulerAngles^ NormalizeRotation(EulerAngles^% rot){return rot->Normalized();} ;
    //Eigen::Matrix3d    NormalizeRotation(Eigen::Matrix3d& rot){return rot;};
    //Eigen::Quaterniond NormalizeRotation(Eigen::Quaterniond& rot){return rot.normalized();};
    //Eigen::AngleAxisd  NormalizeRotation(Eigen::AngleAxisd& rot){return AngleAxisd(rot.angle(),rot.axis().normalized());};

};

}

#endif
