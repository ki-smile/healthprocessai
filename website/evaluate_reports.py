#!/usr/bin/env python3
"""
Script to evaluate LLM-generated process mining reports using Claude
"""

import os
import json
import glob
from datetime import datetime

# Note: This is a template script. You'll need to:
# 1. Install anthropic SDK: pip install anthropic
# 2. Set your API key: export ANTHROPIC_API_KEY="your-key"

def load_evaluation_prompt():
    """Load the evaluation prompt template"""
    with open('evaluation_prompt.md', 'r') as f:
        return f.read()

def load_report(filepath):
    """Load a single report file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None

def create_evaluation_request(prompt_template, report_content, model_name, case_name):
    """Create the evaluation request for Claude"""
    
    evaluation_prompt = f"""
{prompt_template}

---

## REPORT TO EVALUATE

**Model**: {model_name}
**Case**: {case_name}

### Report Content:

{report_content}

---

Please evaluate this report according to the rubric and guidelines provided above. Provide detailed scores and justifications for each criterion.
"""
    
    return evaluation_prompt

def evaluate_with_claude(evaluation_prompt):
    """
    Send evaluation request to Claude API
    
    Note: This is a template. You need to:
    1. Install anthropic: pip install anthropic
    2. Set API key: export ANTHROPIC_API_KEY="your-key"
    """
    
    # Template code for Claude API call
    template_code = """
    from anthropic import Anthropic
    
    client = Anthropic(
        api_key=os.environ.get("ANTHROPIC_API_KEY"),
    )
    
    message = client.messages.create(
        model="claude-3-opus-20240229",  # or another model
        max_tokens=4000,
        temperature=0.2,  # Lower temperature for consistent evaluation
        messages=[
            {
                "role": "user",
                "content": evaluation_prompt
            }
        ]
    )
    
    return message.content[0].text
    """
    
    # For demonstration, return a template response
    return """
MODEL: [Model Name]
CASE: [Case Name]

SCORES:
- Relevance: [TBD] - [Evaluation pending]
- Structure & Presentation: [TBD] - [Evaluation pending]
- Understandability: [TBD] - [Evaluation pending]
- Completeness: [TBD] - [Evaluation pending]
- Innovation: [TBD] - [Evaluation pending]
- Accuracy: [TBD] - [Evaluation pending]

AVERAGE SCORE: [TBD]

[Full evaluation would be provided by Claude API]
"""

def parse_evaluation_scores(evaluation_text):
    """Parse scores from Claude's evaluation response"""
    scores = {}
    
    # Simple parsing - would need to be more robust for production
    lines = evaluation_text.split('\n')
    for line in lines:
        if 'Relevance:' in line:
            try:
                score = float(line.split(':')[1].split('-')[0].strip())
                scores['relevance'] = score
            except:
                pass
        # Similar for other criteria...
    
    return scores

def main():
    """Main evaluation pipeline"""
    
    # Configuration
    base_path = "../legacy_original/R/Reports"
    cases = {
        "case1": "Case I - Infection",
        "case2": "Case II - Organ Damage",
        "case3": "Case III - Glomerular Filtration Rate",
        "case4": "Case IV - Kidney Disease Progression"
    }
    
    models = {
        "anthropic": "Anthropic Claude",
        "deepseek": "DeepSeek R1",
        "google": "Google Gemini",
        "openai": "OpenAI GPT-4",
        "x-ai": "Grok 4"
    }
    
    # Load evaluation prompt
    prompt_template = load_evaluation_prompt()
    
    # Results storage
    evaluation_results = {}
    
    print("=" * 80)
    print("LLM Process Mining Report Evaluation")
    print("=" * 80)
    print()
    
    # Evaluate each model for each case
    for case_id, case_name in cases.items():
        print(f"\n📊 Evaluating {case_name}")
        print("-" * 40)
        
        evaluation_results[case_id] = {}
        case_path = os.path.join(base_path, case_name)
        
        for model_key, model_name in models.items():
            # Find the report file for this model
            pattern = f"Report_{model_key}*.md"
            report_files = glob.glob(os.path.join(case_path, pattern))
            
            if report_files:
                report_file = report_files[0]
                print(f"\n  🤖 {model_name}: {os.path.basename(report_file)}")
                
                # Load report
                report_content = load_report(report_file)
                
                if report_content:
                    # Create evaluation request
                    evaluation_prompt = create_evaluation_request(
                        prompt_template, 
                        report_content, 
                        model_name, 
                        case_name
                    )
                    
                    # Evaluate with Claude (or mock for demonstration)
                    print("     Sending to Claude for evaluation...")
                    evaluation = evaluate_with_claude(evaluation_prompt)
                    
                    # Parse scores
                    scores = parse_evaluation_scores(evaluation)
                    
                    # Store results
                    evaluation_results[case_id][model_key] = {
                        "model_name": model_name,
                        "report_file": os.path.basename(report_file),
                        "evaluation": evaluation,
                        "scores": scores,
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    print("     ✅ Evaluation complete")
                else:
                    print("     ❌ Could not load report")
            else:
                print(f"\n  ⚠️  No report found for {model_name}")
    
    # Save results
    output_file = f"evaluation_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w') as f:
        json.dump(evaluation_results, f, indent=2)
    
    print("\n" + "=" * 80)
    print(f"✅ Evaluation complete! Results saved to: {output_file}")
    print("=" * 80)
    
    # Generate summary statistics
    print("\n📈 Summary Statistics:")
    print("-" * 40)
    
    # This would calculate average scores per model across all cases
    # Implementation depends on successful parsing of Claude's responses
    
    return evaluation_results

if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   LLM Report Evaluation Script                                ║
║   Using Claude for Healthcare Process Mining Report Scoring   ║
║                                                                ║
║   Note: This is a template script. To use with Claude API:    ║
║   1. Install: pip install anthropic                          ║
║   2. Set key: export ANTHROPIC_API_KEY="your-key"            ║
║   3. Uncomment and modify the evaluate_with_claude function  ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
    """)
    
    results = main()