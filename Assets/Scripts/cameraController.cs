using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cameraController : MonoBehaviour {

    public GameObject target;
    private float x, y;
    private float distance;

	// Use this for initialization
	void Start () {
        x = 0.0f;
        y = 0.0f;
        distance = 10;

        Vector3 vector = new Vector3(0, 0, 1);
        vector = Quaternion.Euler(y, x, 0) * vector;
        transform.position = target.transform.position + (vector * distance);

        transform.LookAt(target.transform);
        transform.LookAt(target.transform);
    }

    void updateCameraPosition()
    {
        Vector3 vector = new Vector3(0, 0, 1);
        vector = Quaternion.Euler(y, x, 0) * vector;
        transform.position = target.transform.position + (vector * distance);

        transform.LookAt(target.transform);
    }
	
	// Update is called once per frame
	void Update () {

        if (Input.GetAxis("Mouse ScrollWheel") > 0f) // forward
        {
            distance -= distance/10.0f;
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0f) // backwards
        {
            distance += distance / 10.0f;
        }

        if (distance < 2.5)
            distance = 2.5f;
        else if (distance > 40)
            distance = 40;

        if (Input.GetMouseButton(1))
        {
            x += Input.GetAxis("Mouse X") * 5;
            y += Input.GetAxis("Mouse Y") * 5;

            if (y > 89.9f)
                y = 89.9f;
            else if (y < -89.9f)
                y = -89.9f;
            if (x > 360 || x < -360)
                x = Mathf.Abs(x) - 360;
        }

        updateCameraPosition();
    }
}
