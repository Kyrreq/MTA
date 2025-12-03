// ml-interface/fx/ring.fx
// Proceduralny Shader Pierścienia (Progress Ring)

float progress = 1.0;       // Stan wypełnienia (0.0 - 1.0)
float thickness = 0.15;     // Grubość pierścienia (0.0 - 0.5)
float4 color = float4(1,1,1,1);       // Kolor postępu
float4 bgColor = float4(0.2, 0.2, 0.2, 0.6); // Kolor tła (pustego paska)

struct PSInput {
    float2 TexCoord : TEXCOORD0;
};

float4 PixelShader_Main(PSInput PS) : COLOR0 {
    // Przeliczamy UV (0..1) na środek (-0.5..0.5)
    float2 uv = PS.TexCoord - 0.5;
    float len = length(uv);
    
    // 1. Wycinamy kształt pierścienia
    // Jeśli piksel jest za daleko lub za blisko środka -> przezroczysty
    if (len > 0.5 || len < (0.5 - thickness)) {
        return float4(0,0,0,0); 
    }
    
    // 2. Obliczamy kąt piksela (Zegarowo od góry)
    // atan2(y, x) zwraca kąt. Manipulujemy nim, by 0 było na górze.
    float angle = degrees(atan2(uv.y, uv.x)); 
    
    // Konwersja układu współrzędnych (Top = 0, Clockwise)
    float val = (angle + 90.0) / 360.0;
    if (val < 0.0) val += 1.0;
    
    // 3. Kolorowanie
    if (val <= progress) {
        return color; // Część "zapełniona"
    } else {
        return bgColor; // Część "pusta" (tło)
    }
}

technique circle {
    pass P0 {
        PixelShader = compile ps_2_0 PixelShader_Main();
    }
}