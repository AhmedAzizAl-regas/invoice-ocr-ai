import 'dart:convert';
import '../config/app_config.dart';
import '../network/api_client.dart';
import 'offline_parser_service.dart';

/// LlmService communicates with OpenAI and Gemini API endpoints to format
/// raw OCR text into structured Invoice JSON.
class LlmService {
  final ApiClient _apiClient;

  LlmService(this._apiClient);

  /// Formulates the prompt asking the LLM to structure the raw OCR text into JSON for any document in the world.
  String _buildSystemPrompt() {
    return '''
You are a universal, multi-lingual AI financial & document extraction system. Your task is to extract structured data from ANY global invoice, bill, receipt, contract, or voucher (including Education & University Tuition, Real Estate Rent & Property Sales, Vehicle Sales, Water & Electricity Utilities, Hospital & Medical bills, Pharmacy slips, Hotel receipts, Logistics, Bank Transfers, and Purchase/Sales invoices).
You must return a valid JSON object matching the schema below. Do not include markdown formatting or explanations. Only return JSON.

JSON Schema:
{
  "document_category": "string ('education_tuition' for school/university fees, 'real_estate_rent' for house/shop rent, 'real_estate_sale' for property/land sales contracts, 'vehicle_sale' for car/vehicle sale contracts, 'utility' for electricity/water/telecom, 'medical' for hospital/clinic bills, 'pharmacy' for medicine slips, 'hotel' for hotel receipts, 'logistics' for shipping/customs, 'bank_financial' for bank deposit/transfer/credit note slips, 'sales_invoice' for sales invoices, 'purchase_invoice' for purchasing invoices, 'retail_invoice' for retail sales, or 'general')",
  "detected_language": "string ('ar' for Arabic, 'en' for English, or 'bilingual' if both present)",
  "document_type": "string ('invoice', 'bank_transfer', 'receipt_voucher', 'contract_deed', 'medical_report', 'hotel_folio', 'utility_bill', 'tuition_voucher')",
  "document_title": "string (Exact title of the document in original language, e.g., 'فاتورة رسوم دراسية', 'عقد إيجار شقة', 'عقد بيع عقار', 'عقد مبايعة سيارة', 'إشعار دائن (إيداع نقدي)', 'Water Bill', 'Vehicle Purchase Agreement', or null)",
  "store_name": "string (Name of the school/university, landlord/agency, car showroom, hospital, bank, utility company, or seller. If not found, use Unknown)",
  "invoice_number": "string (Invoice #, Ref #, Student ID #, Lease Contract #, Deed #, VIN/Chassis #, Meter #, Room #, or null)",
  "date": "string (ISO8601 format yyyy-MM-dd, or null)",
  "time": "string (24h time format HH:mm, or null)",
  "currency": "string (3-letter currency code, e.g., USD, SAR, YER, AED, EUR, GBP. Default is SAR if undetermined)",
  "subtotal": double (Total before tax. Default 0.0),
  "tax": double (Total tax amount. Default 0.0),
  "discount": double (Total discount amount. Default 0.0),
  "total": double (Final total transaction amount. Default 0.0),
  "payment_method": "string (e.g., 'إيداع نقدي', 'Cash', 'Insurance', 'Card', 'Installment', 'Transfer', or null)",
  "sender_name": "string (Student Name, Tenant Name, Buyer Name, Depositor, Sender, Patient Name, or null)",
  "receiver_name": "string (University Name, Landlord Name, Seller Name, Beneficiary, Customer Name, Doctor Name, or null)",
  "account_number": "string (Student ID, Lease Contract #, Deed/Plot #, VIN/Chassis #, Meter #, Account #, or null)",
  "branch": "string (Faculty/Department, Building/Unit #, Showroom Branch, City/District, Ward, or null)",
  "employee_name": "string (Dean/Accountant, Agent, Sales Rep, Teller, Cashier, Doctor, or null)",
  "notes": "string (Notes, Payment terms, Written amount in words, Lease duration, Vehicle condition, or null)",

  "dynamic_metadata": [
    {
      "label": "string (Original label e.g., 'اسم الطالب', 'المؤجر', 'المستأجر', 'رقم الصك', 'رقم الهيكل', 'رقم العداد', 'اسم المريض', 'Batch No')",
      "value": "string (Extracted value in original language)"
    }
  ],

  "table_columns": [
    "string (Original table column header names e.g., ['Course/Subject', 'Credit Hours', 'Fee'] or ['Item/Service', 'Qty', 'Unit Price', 'Total'])"
  ],

  "table_rows": [
    [
      "string (Extracted row cell value matching table_columns)"
    ]
  ],

  "items": [
    {
      "product_name": "string (Name of tuition fee, property unit, vehicle model, medicine, test, or product)",
      "quantity": double (Quantity, default 1.0),
      "unit_price": double (Price per unit, default 0.0),
      "total_price": double (Total price, default 0.0)
    }
  ]
}

Instructions:
1. Detect category accurately:
   - For School/University tuition, set document_category="education_tuition" and extract Student Name, Student ID, Major/Faculty, Semester, Tuition fees.
   - For House/Shop/Apartment Rentals, set document_category="real_estate_rent" and extract Tenant Name, Landlord Name, Unit #, Lease Period, Rental Amount.
   - For Real Estate/Land Sales, set document_category="real_estate_sale" and extract Buyer Name, Seller Name, Deed/Plot #, Location, Sale Price.
   - For Vehicle Sales, set document_category="vehicle_sale" and extract Buyer, Seller, Vehicle Make/Model, VIN/Chassis #, Plate #, Year, Price.
   - For Water/Electricity/Gas, set document_category="utility" and extract Meter #, Previous Reading, Current Reading, Consumption Amount.
   - For Purchasing & Sales invoices, set document_category="purchase_invoice" or "sales_invoice".
2. Preserve original text and language (especially Arabic names, titles, academic terms, and legal terms). Do NOT translate Arabic into English.
3. Extract all specific document details into "dynamic_metadata" list of {"label": "...", "value": "..."} in the original language.
4. Output 100% valid JSON matching the schema.
''';
  }

  /// Parses the raw OCR text using the chosen engine. Fallbacks to local offline parsing if network fails.
  Future<Map<String, dynamic>> parseInvoiceText({
    required String rawText,
    required String engine, // 'openai' or 'gemini'
    required String apiKey,
    String? modelName,
  }) async {
    if (apiKey.isEmpty) {
      return OfflineParserService.parseRawText(rawText);
    }

    try {
      final systemPrompt = _buildSystemPrompt();

      if (engine == 'openai') {
        final model = modelName ?? AppConfig.openaiModelName;
        final url = 'https://api.openai.com/v1/chat/completions';
        final headers = {
          'Authorization': 'Bearer $apiKey',
        };
        final body = {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Raw OCR Text:\n$rawText'},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        };

        final response = await _apiClient.post(url, headers: headers, body: body);
        final content = response['choices'][0]['message']['content'] as String;
        return jsonDecode(content);
      } else {
        // Gemini API
        final model = modelName ?? AppConfig.geminiModelName;
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
        final body = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\nRaw OCR Text:\n$rawText'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.1,
          }
        };

        final response = await _apiClient.post(url, body: body);
        final text = response['candidates'][0]['content']['parts'][0]['text'] as String;
        return jsonDecode(text);
      }
    } catch (_) {
      // Offline fallback: If network fails or host lookup fails, use local heuristic parser
      return OfflineParserService.parseRawText(rawText);
    }
  }
}
