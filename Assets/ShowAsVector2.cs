using UnityEngine;
using UnityEditor;
using System;

// The property drawer class should be placed in an editor script, inside a folder called Editor.
// Use with "[MyToggle]" before a float shader property.

public class ShowAsVector2 : MaterialPropertyDrawer
{
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        if (prop.type == MaterialProperty.PropType.Vector)
        {
            EditorGUIUtility.labelWidth = 0f;
            EditorGUIUtility.fieldWidth = 0f;

            if (!EditorGUIUtility.wideMode)
            {
                EditorGUIUtility.wideMode = true;
                EditorGUIUtility.labelWidth = EditorGUIUtility.currentViewWidth - 212;
            }

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            Vector4 vec = EditorGUI.Vector2Field(position, label, prop.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                prop.vectorValue = vec;
            }
        }
        else
            editor.DefaultShaderProperty(prop, label.text);

    }
}