#pragma once

/** \class VECTOR3D
* Minimal 3D vector storage for the metaball renderer.
*/
class VECTOR3D
{
public:
	VECTOR3D(void) : x(0.0f), y(0.0f), z(0.0f)
	{}

	VECTOR3D(float newX, float newY, float newZ) : x(newX), y(newY), z(newZ)
	{}

	VECTOR3D(const float * rhs) : x(*rhs), y(*(rhs+1)), z(*(rhs+2))
	{}

	VECTOR3D(const VECTOR3D & rhs) : x(rhs.x), y(rhs.y), z(rhs.z)
	{}

	void Set(float newX, float newY, float newZ)
	{	x=newX;	y=newY;	z=newZ;	}

	void LoadZero(void)
	{	x=y=z=0.0f;	}

	/// Cast to pointer for glVertex3fv and glNormal3fv.
	operator float* () const {return (float*) this;}
	operator const float* () const {return (const float*) this;}

	float x;
	float y;
	float z;
};
