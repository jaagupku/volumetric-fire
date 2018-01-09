using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

public class UIController : MonoBehaviour
{


	[SerializeField] private List<GameObject> panels;

	[SerializeField] private List<GameObject> volumetricFires;

	[SerializeField] private InputField darkR;
	[SerializeField] private InputField darkG;
	[SerializeField] private InputField darkB;
	
	[SerializeField] private InputField lightR;
	[SerializeField] private InputField lightG;
	[SerializeField] private InputField lightB;
	
	[SerializeField] private InputField thirdR;
	[SerializeField] private InputField thirdG;
	[SerializeField] private InputField thirdB;
	
	[SerializeField] private InputField smokeR;
	[SerializeField] private InputField smokeG;
	[SerializeField] private InputField smokeB;


	private int currentShaderIndex = 4;

	private List<Material> originalMaterials;

	public void OnSliderValueChanged(Slider target)
	{
		volumetricFires[currentShaderIndex].GetComponent<MeshRenderer>().materials[0].SetFloat(target.tag, target.value);

	}

	public void OnInputValueChanged(InputField target)
	{
		Color color = new Color32();
		switch (target.tag)
		{
				case("_DarkColor"):
					color = new Color32(r: (byte)int.Parse(darkR.text), g: (byte)int.Parse(darkG.text), b: (byte)int.Parse(darkB.text), a: 255);
					break;
				case("_LightColor"):
					color = new Color32(r: (byte)int.Parse(lightR.text), g: (byte)int.Parse(lightG.text), b: (byte)int.Parse(lightB.text), a: 255);
					break;
				case("_ThirdColor"):
					color = new Color32(r: (byte)int.Parse(thirdR.text), g: (byte)int.Parse(thirdG.text), b: (byte)int.Parse(thirdB.text), a: 255);
					break;
				case("_SmokeColor"):
					color = new Color32(r: (byte)int.Parse(smokeR.text), g: (byte)int.Parse(smokeG.text), b: (byte)int.Parse(smokeB.text), a: 255);
					break;
				default:
					print("sum ting wong");
					break;
		}
		volumetricFires[currentShaderIndex].GetComponent<MeshRenderer>().materials[0].SetColor(target.tag, color);
	}

	public void OnToggleValueChanged(Toggle target)
	{
		float isOn = target.isOn ? 1.0f : 0.0f;
		volumetricFires[currentShaderIndex].GetComponent<MeshRenderer>().materials[0].SetFloat(target.tag, isOn);
	}

	public void OnDropDownValueChanged(Dropdown target)
	{
		
		volumetricFires[currentShaderIndex].GetComponent<MeshRenderer>().materials[0].SetFloat(target.tag, target.value);
	}
	
	
	// Use this for initialization
	void Start ()
	{
		originalMaterials = new List<Material>();

		originalMaterials = volumetricFires.Select(vFire => new Material(vFire.GetComponent<MeshRenderer>().materials[0])).ToList();
	}
	
	// Update is called once per frame
	void Update () {
		if (Input.GetKeyDown(KeyCode.M))
		{
			panels.ForEach(p => p.SetActive(!p.activeInHierarchy));
		}
		if (Input.GetKeyDown(KeyCode.R))
		{
			volumetricFires[currentShaderIndex].GetComponent<MeshRenderer>().material = originalMaterials[currentShaderIndex];
		}
		if (Input.GetKeyDown(KeyCode.LeftArrow))
		{
			volumetricFires[currentShaderIndex].SetActive(false);

			currentShaderIndex = ((currentShaderIndex-1) + volumetricFires.Count) % volumetricFires.Count;

			volumetricFires[currentShaderIndex].SetActive(true);
		}
		if (Input.GetKeyDown(KeyCode.RightArrow))
		{
			volumetricFires[currentShaderIndex].SetActive(false);

			currentShaderIndex = (currentShaderIndex+1) % volumetricFires.Count;

			volumetricFires[currentShaderIndex].SetActive(true);
		}
	}
}
