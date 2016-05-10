#version 120
varying vec3 position;
varying vec3 normal;
varying vec3 eye;
varying vec3 worldView;

uniform mat4 viewMatrix;
uniform mat4 invViewMatrix;

void main()
{
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    vec4 eyeVertex = gl_ModelViewMatrix * gl_Vertex;
    position = eyeVertex.xyz;
    eye = normalize(-position);
   
    vec3 worldPos = (invViewMatrix * eyeVertex).xyz;
    vec3 worldCamPos = (invViewMatrix[3]).xyz; // translation part of the matrix
    worldView = normalize(worldPos - worldCamPos); // vector from camera to vertex
   
    normal = normalize(gl_NormalMatrix * gl_Normal);
   
    gl_Position = ftransform();
}