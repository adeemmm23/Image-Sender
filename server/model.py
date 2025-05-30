import cv2
import sys
import logging


def check(file_path):
    frame = cv2.imread(file_path)
    if frame is None:
        return {"error": "Invalid image format"}

    return {
        'data': "Image processed successfully",
    }


if __name__ == "__main__":
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        result = check(file_path)
        logging.info(result)
    else:
        logging.error("Please provide image file path as an argument")
        sys.exit(1)
