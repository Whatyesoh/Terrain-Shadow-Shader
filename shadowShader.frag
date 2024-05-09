extern Image heightMap;
extern Image normalMap;
extern number pixelSize;
extern float steps;
extern vec3 sun;
extern float waterLevel;

vec4 sunLight = vec4(1,.9,.8,1);

//Shader
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {

    //Find scaling(screen dimensions)
    float scaleX = screen_coords.x / texture_coords.x;
    float scaleY = screen_coords.y / texture_coords.y;

    vec3 view = vec3(.5,.5,3);
    vec4 light = sunLight;

    //Misalign pixels

    //screen_coords.y += 4*sin((screen_coords.x * pixelSize)/10);
    //texture_coords.y = screen_coords.y / scaleY;

    //All subpixels become the top-left subpixel in their group

    if ((screen_coords.x-1) - pixelSize * floor((screen_coords.x-1)/ pixelSize) != 0) {
        screen_coords.x -= (screen_coords.x-1) - pixelSize * floor((screen_coords.x-1)/ pixelSize) + 1;
        texture_coords.x = screen_coords.x / scaleX;
    }
    if ((screen_coords.y-1) - pixelSize * floor((screen_coords.y-1)/ pixelSize) != 0) {
        screen_coords.y -= (screen_coords.y-1) - pixelSize * floor((screen_coords.y-1)/ pixelSize) + 1;
        texture_coords.y = screen_coords.y / scaleY;
    }
    
    //Initialize vectors
    float startHeight = (Texel(heightMap,texture_coords).a + Texel(heightMap,texture_coords).b + Texel(heightMap,texture_coords).g + Texel(heightMap,texture_coords).r)/4;
    vec3 start = vec3(float(texture_coords.x),float(texture_coords.y),startHeight);
    vec3 dir = sun - start;
    vec4 pixel = Texel(texture,texture_coords);
    vec4 normal = Texel(normalMap,texture_coords);
    vec3 normalVec = vec3(normal.x,normal.y,normal.z);

    //Shading based on the normal
    float normalShade = (dot(dir,normalVec) + 1)/2;

    vec3 viewDir = view-start;
    vec3 sunWithView = normalize(dir + viewDir);

    //Shadows being cast
    float castShade = 1;
    for (int i = 0; i < steps; i += 1) {
        vec3 position = i/steps * dir + start;

        if (position.z >= 1) {
            break;
        }

        vec4 rayHeights = Texel(heightMap,vec2(position.x,position.y));

        float height = (rayHeights.a + rayHeights.b + rayHeights.g + rayHeights.r)/4;

        if (position.z < height) {
            castShade = .5 * (length(position - start)+1.1);
            break;
        }

        i = i + int(10 * (position.z - height));
    }
    /*
    if (startHeight <= waterLevel && castShade == 1) {
        vec4 specular = pow(max(dot(normalVec,sunWithView),0.),32.) * light;

        light += specular;
    }
    */

    color.a = normalShade * castShade;

    color *= light;

    return pixel * color;
}