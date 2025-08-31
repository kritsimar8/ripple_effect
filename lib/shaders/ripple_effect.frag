#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform sampler2D iChannel0;

const float amplitude = 0.05; // Default amplitude of the ripple
const float frequency = 10.0; // Default frequency of the ripple
const float decay = 2.0; // Default decay rate of the ripple
const float speed = 1.0; // Default speed of the ripple

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

   
    vec2 uv = fragCoord / iResolution.xy;

    
    vec2 origin = iMouse.xy / iResolution.xy;

   
    float distance = length(uv - origin);
   
    float delay = distance / speed;

  
    float time = iTime - delay;
    time = max(0.0, time);

   
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

   
    vec2 n = normalize(uv - origin);

   
    vec2 newPosition = uv + rippleAmount * n;

   
    vec3 color = texture(iChannel0, newPosition).rgb;

    
    color += 0.1 * (rippleAmount / amplitude);

    
    fragColor = vec4(color, 1.0);
}