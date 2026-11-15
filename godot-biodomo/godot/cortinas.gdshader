shader_type spatial;
render_mode cull_disabled;
uniform float cobertura : hint_range(0.0,1.0) = 0.0;
void vertex(){
 float theta = acos(clamp((VERTEX.y-1.0)/13.32,0.0,1.0));
 float nuevo = theta * mix(0.055,1.0,cobertura);
 float a = atan(VERTEX.z,VERTEX.x);
 float r = 19.74*sin(nuevo)*(1.0+0.0025*cos(a*144.0));
 VERTEX = vec3(r*cos(a),1.0+13.32*cos(nuevo),r*sin(a));
 NORMAL = normalize(vec3(sin(nuevo)*cos(a)/19.74,cos(nuevo)/13.32,sin(nuevo)*sin(a)/19.74));
}
void fragment(){
 ALBEDO=vec3(0.19,0.34,0.43);
 ROUGHNESS=0.9;
 if(!FRONT_FACING){NORMAL=-NORMAL;}
}
