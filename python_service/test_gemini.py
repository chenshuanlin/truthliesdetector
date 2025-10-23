import google.generativeai as genai

GEMINI_API_KEY = "AIzaSyBZoPr5y8AM3c9VcM5ahIAqfw0ODtRAtQk"

try:
    genai.configure(api_key=GEMINI_API_KEY)
    
    print("正在列出可用的模型...")
    for model in genai.list_models():
        if 'generateContent' in model.supported_generation_methods:
            print(f"✓ {model.name}")
    
    print("\n正在測試 Gemini API...")
    model = genai.GenerativeModel('gemini-2.0-flash')
    response = model.generate_content("請用一句話回答：什麼是假訊息？")
    
    print("✅ Gemini API 測試成功！")
    print(f"回應內容：{response.text}")
    
except Exception as e:
    print(f"❌ Gemini API 測試失敗：{e}")
    import traceback
    traceback.print_exc()
